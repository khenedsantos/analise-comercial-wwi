SET NOCOUNT ON;
-- Read-only source audit. Temporary tables live only in tempdb.
SELECT il.*,i.InvoiceDate,i.CustomerID,i.BillToCustomerID,i.OrderID,i.IsCreditNote,
 CAST(il.ExtendedPrice-il.TaxAmount AS decimal(18,2)) AS AmountExTax
INTO #L FROM Sales.InvoiceLines il JOIN Sales.Invoices i ON i.InvoiceID=il.InvoiceID OPTION (LOOP JOIN, MAXDOP 1);
SELECT 'volumes' AS section,
 (SELECT COUNT_BIG(*) FROM Sales.Invoices) AS invoices,(SELECT COUNT_BIG(*) FROM Sales.InvoiceLines) AS invoice_lines,
 (SELECT COUNT_BIG(*) FROM Sales.Customers) AS customers,(SELECT COUNT_BIG(*) FROM Warehouse.StockItems) AS products,
 COUNT(DISTINCT CustomerID) AS invoiced_customers,COUNT(DISTINCT StockItemID) AS invoiced_products,
 MIN(InvoiceDate) AS first_invoice,MAX(InvoiceDate) AS last_invoice,COUNT_BIG(*) AS joined_lines FROM #L;
SELECT 'document_types' AS section,i.IsCreditNote,COUNT_BIG(*) AS documents,MIN(i.InvoiceDate) AS first_date,MAX(i.InvoiceDate) AS last_date,
 SUM(CASE WHEN i.OrderID IS NULL THEN 1 ELSE 0 END) AS null_order_id FROM Sales.Invoices i GROUP BY i.IsCreditNote;
SELECT 'signs_financials' AS section,IsCreditNote,COUNT_BIG(*) AS lines,
 SUM(CAST(Quantity AS bigint)) AS quantity,SUM(AmountExTax) AS amount_ex_tax,SUM(TaxAmount) AS tax,SUM(ExtendedPrice) AS extended_price,SUM(LineProfit) AS line_profit,
 SUM(CASE WHEN Quantity<0 THEN 1 ELSE 0 END) AS negative_qty,SUM(CASE WHEN Quantity=0 THEN 1 ELSE 0 END) AS zero_qty,
 SUM(CASE WHEN UnitPrice<0 THEN 1 ELSE 0 END) AS negative_price,SUM(CASE WHEN UnitPrice=0 THEN 1 ELSE 0 END) AS zero_price,SUM(CASE WHEN UnitPrice IS NULL THEN 1 ELSE 0 END) AS null_price,
 SUM(CASE WHEN TaxAmount<0 THEN 1 ELSE 0 END) AS negative_tax,SUM(CASE WHEN TaxAmount=0 THEN 1 ELSE 0 END) AS zero_tax,
 SUM(CASE WHEN ExtendedPrice<0 THEN 1 ELSE 0 END) AS negative_extended,SUM(CASE WHEN ExtendedPrice=0 THEN 1 ELSE 0 END) AS zero_extended,
 SUM(CASE WHEN LineProfit<0 THEN 1 ELSE 0 END) AS negative_profit,SUM(CASE WHEN LineProfit=0 THEN 1 ELSE 0 END) AS zero_profit,
 MIN(UnitPrice) AS min_price,MAX(UnitPrice) AS max_price,MIN(LineProfit) AS min_profit,MAX(LineProfit) AS max_profit,
 MIN(Quantity) AS min_qty,MAX(Quantity) AS max_qty FROM #L GROUP BY IsCreditNote;
SELECT 'reconciliation' AS section,IsCreditNote,COUNT_BIG(*) AS lines,
 SUM(CASE WHEN AmountExTax<>ROUND(Quantity*UnitPrice,2) THEN 1 ELSE 0 END) AS net_vs_qty_price_mismatches,
 MAX(ABS(AmountExTax-ROUND(Quantity*UnitPrice,2))) AS max_net_diff,
 SUM(CASE WHEN TaxAmount<>ROUND(Quantity*UnitPrice*TaxRate/100.0,2) THEN 1 ELSE 0 END) AS tax_mismatches,
 MAX(ABS(TaxAmount-ROUND(Quantity*UnitPrice*TaxRate/100.0,2))) AS max_tax_diff,
 SUM(CASE WHEN ExtendedPrice<>ROUND(Quantity*UnitPrice,2)+ROUND(Quantity*UnitPrice*TaxRate/100.0,2) THEN 1 ELSE 0 END) AS extended_mismatches,
 SUM(CASE WHEN AmountExTax-LineProfit<0 THEN 1 ELSE 0 END) AS negative_implied_cost,
 SUM(CASE WHEN LineProfit>AmountExTax AND IsCreditNote=0 THEN 1 ELSE 0 END) AS profit_gt_sales
FROM #L GROUP BY IsCreditNote;
SELECT 'last_cost_comparison' AS section,l.IsCreditNote,COUNT_BIG(*) AS lines,
 SUM(CASE WHEN l.LineProfit<>ROUND(l.Quantity*(l.UnitPrice-h.LastCostPrice),2) THEN 1 ELSE 0 END) AS profit_vs_current_last_cost_mismatches,
 MIN(CASE WHEN l.Quantity<>0 THEN CAST((l.AmountExTax-l.LineProfit)/l.Quantity AS decimal(18,6)) END) AS min_implied_unit_cost,
 MAX(CASE WHEN l.Quantity<>0 THEN CAST((l.AmountExTax-l.LineProfit)/l.Quantity AS decimal(18,6)) END) AS max_implied_unit_cost
FROM #L l JOIN Warehouse.StockItemHoldings h ON l.StockItemID=h.StockItemID GROUP BY l.IsCreditNote;
SELECT 'monthly' AS section,YEAR(InvoiceDate) AS year,MONTH(InvoiceDate) AS month,MIN(InvoiceDate) AS first_date,MAX(InvoiceDate) AS last_date,
 COUNT(DISTINCT InvoiceDate) AS days_with_documents,COUNT(DISTINCT InvoiceID) AS documents,COUNT_BIG(*) AS lines,
 SUM(CASE WHEN IsCreditNote=0 THEN AmountExTax ELSE 0 END) AS sales_ex_tax,
 SUM(CASE WHEN IsCreditNote=1 THEN AmountExTax ELSE 0 END) AS credits_signed,
 SUM(LineProfit) AS profit FROM #L GROUP BY YEAR(InvoiceDate),MONTH(InvoiceDate) ORDER BY 2,3;
SELECT 'daily' AS section,InvoiceDate,COUNT_BIG(*) AS documents FROM Sales.Invoices GROUP BY InvoiceDate ORDER BY InvoiceDate;
SELECT 'categories_customers' AS section,cc.CustomerCategoryID,cc.CustomerCategoryName,COUNT(c.CustomerID) AS registered_customers,
 COUNT(CASE WHEN EXISTS_PLACEHOLDER=1 THEN 1 END) AS classified_customers
FROM Sales.CustomerCategories cc LEFT JOIN (SELECT *,1 AS EXISTS_PLACEHOLDER FROM Sales.Customers) c ON cc.CustomerCategoryID=c.CustomerCategoryID GROUP BY cc.CustomerCategoryID,cc.CustomerCategoryName;
SELECT 'customer_classification' AS section,COUNT_BIG(*) AS customers,
 SUM(CASE WHEN cc.CustomerCategoryID IS NULL THEN 1 ELSE 0 END) AS missing_category,
 SUM(CASE WHEN c.BuyingGroupID IS NULL THEN 1 ELSE 0 END) AS no_buying_group,
 SUM(CASE WHEN c.BuyingGroupID IS NOT NULL AND bg.BuyingGroupID IS NULL THEN 1 ELSE 0 END) AS invalid_buying_group,
 SUM(CASE WHEN c.CustomerID<>c.BillToCustomerID THEN 1 ELSE 0 END) AS different_bill_to
FROM Sales.Customers c LEFT JOIN Sales.CustomerCategories cc ON c.CustomerCategoryID=cc.CustomerCategoryID LEFT JOIN Sales.BuyingGroups bg ON bg.BuyingGroupID=c.BuyingGroupID;
SELECT 'product_group_counts' AS section,number_of_groups,COUNT_BIG(*) AS products FROM
 (SELECT s.StockItemID,COUNT(g.StockGroupID) AS number_of_groups FROM Warehouse.StockItems s LEFT JOIN Warehouse.StockItemStockGroups g ON s.StockItemID=g.StockItemID GROUP BY s.StockItemID) q GROUP BY number_of_groups ORDER BY 2;
SELECT 'stock_groups' AS section,g.StockGroupID,g.StockGroupName,COUNT(b.StockItemID) AS products FROM Warehouse.StockGroups g LEFT JOIN Warehouse.StockItemStockGroups b ON b.StockGroupID=g.StockGroupID GROUP BY g.StockGroupID,g.StockGroupName ORDER BY 2;
SELECT 'bridge_duplicates' AS section,COUNT_BIG(*) AS duplicate_pairs FROM
 (SELECT StockItemID,StockGroupID FROM Warehouse.StockItemStockGroups GROUP BY StockItemID,StockGroupID HAVING COUNT(*)>1) q;
SELECT 'bridge_join_effect' AS section,(SELECT COUNT_BIG(*) FROM #L) AS original_lines,COUNT_BIG(*) AS lines_after_join,
 (SELECT SUM(AmountExTax) FROM #L) AS original_amount,SUM(l.AmountExTax) AS amount_after_join FROM #L l JOIN Warehouse.StockItemStockGroups b ON l.StockItemID=b.StockItemID;
SELECT 'geography' AS section,co.CountryName,sp.StateProvinceName,COUNT(DISTINCT c.CustomerID) AS customers,COUNT(DISTINCT ct.CityID) AS cities
FROM Sales.Customers c LEFT JOIN Application.Cities ct ON c.DeliveryCityID=ct.CityID LEFT JOIN Application.StateProvinces sp ON ct.StateProvinceID=sp.StateProvinceID LEFT JOIN Application.Countries co ON sp.CountryID=co.CountryID GROUP BY co.CountryName,sp.StateProvinceName ORDER BY 2,3;
SELECT 'geography_missing' AS section,SUM(CASE WHEN ct.CityID IS NULL THEN 1 ELSE 0 END) AS missing_city,
 SUM(CASE WHEN sp.StateProvinceID IS NULL THEN 1 ELSE 0 END) AS missing_state,SUM(CASE WHEN co.CountryID IS NULL THEN 1 ELSE 0 END) AS missing_country,
 SUM(CASE WHEN c.DeliveryLocation IS NULL THEN 1 ELSE 0 END) AS missing_coordinates FROM Sales.Customers c
LEFT JOIN Application.Cities ct ON c.DeliveryCityID=ct.CityID LEFT JOIN Application.StateProvinces sp ON ct.StateProvinceID=sp.StateProvinceID LEFT JOIN Application.Countries co ON sp.CountryID=co.CountryID;
SELECT 'duplicate_business_lines' AS section,COUNT_BIG(*) AS repeated_groups,COALESCE(SUM(n-1),0) AS extra_lines FROM
 (SELECT InvoiceID,StockItemID,PackageTypeID,Quantity,UnitPrice,TaxRate,TaxAmount,LineProfit,ExtendedPrice,Description,COUNT_BIG(*) n
 FROM Sales.InvoiceLines GROUP BY InvoiceID,StockItemID,PackageTypeID,Quantity,UnitPrice,TaxRate,TaxAmount,LineProfit,ExtendedPrice,Description HAVING COUNT_BIG(*)>1) q;
SELECT 'repeated_product_invoice' AS section,COUNT_BIG(*) AS repeated_pairs,COALESCE(SUM(n-1),0) AS extra_lines FROM
 (SELECT InvoiceID,StockItemID,COUNT_BIG(*) n FROM Sales.InvoiceLines GROUP BY InvoiceID,StockItemID HAVING COUNT_BIG(*)>1) q;
SELECT 'invoice_cardinality' AS section,MIN(n) AS min_lines,MAX(n) AS max_lines,AVG(CAST(n AS decimal(18,4))) AS avg_lines,
 SUM(CASE WHEN n=0 THEN 1 ELSE 0 END) AS invoices_without_lines FROM
 (SELECT i.InvoiceID,COUNT(l.InvoiceLineID) n FROM Sales.Invoices i LEFT JOIN Sales.InvoiceLines l ON i.InvoiceID=l.InvoiceID GROUP BY i.InvoiceID) q;
SELECT 'order_invoice_cardinality' AS section,MIN(n) AS min_invoices,MAX(n) AS max_invoices,SUM(CASE WHEN n>1 THEN 1 ELSE 0 END) AS orders_multiple_invoices FROM
 (SELECT OrderID,COUNT_BIG(*) n FROM Sales.Invoices WHERE OrderID IS NOT NULL GROUP BY OrderID) q;
SELECT 'tax_rates' AS section,TaxRate,IsCreditNote,COUNT_BIG(*) AS lines FROM #L GROUP BY TaxRate,IsCreditNote ORDER BY 2,3;
SELECT 'package_types' AS section,p.PackageTypeName,COUNT_BIG(*) AS lines,SUM(CAST(l.Quantity AS bigint)) AS quantity FROM #L l JOIN Warehouse.PackageTypes p ON l.PackageTypeID=p.PackageTypeID GROUP BY p.PackageTypeName;
SELECT 'credit_reasons' AS section,CreditNoteReason,COUNT_BIG(*) AS documents FROM Sales.Invoices WHERE IsCreditNote=1 GROUP BY CreditNoteReason;
SELECT 'period_other_tables' AS section,'Sales.Orders' AS table_name,MIN(OrderDate) AS min_date,MAX(OrderDate) AS max_date,COUNT_BIG(*) AS rows FROM Sales.Orders
UNION ALL SELECT 'period_other_tables','Sales.CustomerTransactions',MIN(TransactionDate),MAX(TransactionDate),COUNT_BIG(*) FROM Sales.CustomerTransactions;
SELECT 'invoice_transaction_reconciliation' AS section,COUNT_BIG(*) AS invoices,
 SUM(CASE WHEN t.n IS NULL THEN 1 ELSE 0 END) AS invoices_without_transactions,SUM(CASE WHEN t.n>1 THEN 1 ELSE 0 END) AS invoices_multiple_transactions,
 SUM(CASE WHEN l.amount<>t.amount THEN 1 ELSE 0 END) AS amount_mismatches,SUM(CASE WHEN l.tax<>t.tax THEN 1 ELSE 0 END) AS tax_mismatches,
 SUM(CASE WHEN l.extended<>t.extended THEN 1 ELSE 0 END) AS extended_mismatches
FROM Sales.Invoices i LEFT JOIN (SELECT InvoiceID,SUM(AmountExTax) amount,SUM(TaxAmount) tax,SUM(ExtendedPrice) extended FROM #L GROUP BY InvoiceID) l ON i.InvoiceID=l.InvoiceID
LEFT JOIN (SELECT InvoiceID,COUNT_BIG(*) n,SUM(AmountExcludingTax) amount,SUM(TaxAmount) tax,SUM(TransactionAmount) extended FROM Sales.CustomerTransactions WHERE InvoiceID IS NOT NULL GROUP BY InvoiceID) t ON i.InvoiceID=t.InvoiceID;
SELECT 'names_duplicates' AS section,'customer_name' AS field,COUNT_BIG(*) AS duplicate_values FROM (SELECT CustomerName FROM Sales.Customers GROUP BY CustomerName HAVING COUNT(*)>1) q
UNION ALL SELECT 'names_duplicates','product_name',COUNT_BIG(*) FROM (SELECT StockItemName FROM Warehouse.StockItems GROUP BY StockItemName HAVING COUNT(*)>1) q;
SELECT 'unusual_products' AS section,COUNT_BIG(*) AS products,SUM(CASE WHEN Brand IS NULL THEN 1 ELSE 0 END) AS null_brand,
SUM(CASE WHEN Size IS NULL THEN 1 ELSE 0 END) AS null_size,SUM(CASE WHEN ColorID IS NULL THEN 1 ELSE 0 END) AS null_color FROM Warehouse.StockItems;
-- Enforced PK uniqueness is additionally checked by CHECKDB. Audit every declared FK through actual anti-joins.
CREATE TABLE #FK(name sysname,parent_table nvarchar(260),orphans bigint);
DECLARE @sql nvarchar(max)='';
SELECT @sql=@sql+N'INSERT #FK SELECT N'''+REPLACE(f.name,'''','''''')+N''',N'''+SCHEMA_NAME(t.schema_id)+N'.'+t.name+N''',COUNT_BIG(*) FROM '+QUOTENAME(SCHEMA_NAME(t.schema_id))+N'.'+QUOTENAME(t.name)+N' p LEFT JOIN '+QUOTENAME(OBJECT_SCHEMA_NAME(f.referenced_object_id))+N'.'+QUOTENAME(OBJECT_NAME(f.referenced_object_id))+N' r ON p.'+QUOTENAME(COL_NAME(fc.parent_object_id,fc.parent_column_id))+N'=r.'+QUOTENAME(COL_NAME(fc.referenced_object_id,fc.referenced_column_id))+N' WHERE p.'+QUOTENAME(COL_NAME(fc.parent_object_id,fc.parent_column_id))+N' IS NOT NULL AND r.'+QUOTENAME(COL_NAME(fc.referenced_object_id,fc.referenced_column_id))+N' IS NULL;'
FROM sys.foreign_keys f JOIN sys.foreign_key_columns fc ON f.object_id=fc.constraint_object_id JOIN sys.tables t ON t.object_id=f.parent_object_id;
EXEC sys.sp_executesql @sql;
SELECT 'fk_actual' AS section,* FROM #FK ORDER BY parent_table,name;
CREATE TABLE #Nulls(table_name nvarchar(260),column_name sysname,nulls bigint,total_rows bigint);
SET @sql='';
SELECT @sql=@sql+N'INSERT #Nulls SELECT N'''+SCHEMA_NAME(t.schema_id)+'.'+t.name+N''',N'''+c.name+N''',COUNT_BIG(*)-COUNT_BIG('+QUOTENAME(c.name)+N'),COUNT_BIG(*) FROM '+QUOTENAME(SCHEMA_NAME(t.schema_id))+N'.'+QUOTENAME(t.name)+N';'
FROM sys.tables t JOIN sys.columns c ON t.object_id=c.object_id
WHERE (SCHEMA_NAME(t.schema_id)='Sales' AND t.name IN ('Invoices','InvoiceLines','Customers','CustomerCategories','BuyingGroups'))
OR (SCHEMA_NAME(t.schema_id)='Warehouse' AND t.name IN ('StockItems','StockGroups','StockItemStockGroups','StockItemHoldings'));
EXEC sys.sp_executesql @sql;
SELECT 'nulls' AS section,* FROM #Nulls ORDER BY table_name,column_name;
