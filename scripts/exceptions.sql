SET NOCOUNT ON;
SELECT 'negative_profit' AS section,COUNT_BIG(*) AS lines,COUNT(DISTINCT InvoiceID) AS invoices,COUNT(DISTINCT StockItemID) AS products,
 SUM(ExtendedPrice-TaxAmount) AS sales_ex_tax,SUM(LineProfit) AS negative_profit_total FROM Sales.InvoiceLines WHERE LineProfit<0 OPTION (MAX_GRANT_PERCENT=1);
SELECT 'negative_profit_products' AS section,l.StockItemID,s.StockItemName,COUNT_BIG(*) AS lines,MIN(l.UnitPrice) AS min_price,MAX(l.UnitPrice) AS max_price,h.LastCostPrice,
 SUM(l.LineProfit) AS negative_profit_total FROM Sales.InvoiceLines l JOIN Warehouse.StockItems s ON l.StockItemID=s.StockItemID JOIN Warehouse.StockItemHoldings h ON l.StockItemID=h.StockItemID WHERE l.LineProfit<0 GROUP BY l.StockItemID,s.StockItemName,h.LastCostPrice OPTION (MAX_GRANT_PERCENT=1);
SELECT TOP (5) 'negative_profit_examples' AS section,l.InvoiceLineID,l.InvoiceID,l.StockItemID,l.Quantity,l.UnitPrice,l.TaxRate,l.TaxAmount,l.ExtendedPrice,l.LineProfit,h.LastCostPrice FROM Sales.InvoiceLines l JOIN Warehouse.StockItemHoldings h ON l.StockItemID=h.StockItemID WHERE l.LineProfit<0 ORDER BY l.InvoiceLineID OPTION (MAX_GRANT_PERCENT=1);
SELECT 'temporal_customers_at_invoice' AS section,COUNT_BIG(*) AS joined_documents,COUNT(DISTINCT i.InvoiceID) AS invoices,
 SUM(CASE WHEN c.CustomerID IS NULL THEN 1 ELSE 0 END) AS no_valid_version,
 SUM(CASE WHEN c.DeliveryCityID<>cur.DeliveryCityID THEN 1 ELSE 0 END) AS different_city,
 SUM(CASE WHEN c.CustomerCategoryID<>cur.CustomerCategoryID THEN 1 ELSE 0 END) AS different_category
FROM Sales.Invoices i LEFT JOIN Sales.Customers FOR SYSTEM_TIME ALL c ON i.CustomerID=c.CustomerID AND CAST(i.InvoiceDate AS datetime2)>=c.ValidFrom AND CAST(i.InvoiceDate AS datetime2)<c.ValidTo
JOIN Sales.Customers cur ON cur.CustomerID=i.CustomerID OPTION (LOOP JOIN,MAX_GRANT_PERCENT=1);
SELECT 'fiscal_reference' AS section,OBJECT_SCHEMA_NAME(object_id) AS schema_name,OBJECT_NAME(object_id) AS object_name FROM sys.sql_modules WHERE definition LIKE '%November%' OR definition LIKE '%Fiscal%';
