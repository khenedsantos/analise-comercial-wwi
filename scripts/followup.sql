SET NOCOUNT ON;
SELECT 'access' AS section,IS_SRVROLEMEMBER('sysadmin') AS is_sysadmin,USER_NAME() AS database_user;
SELECT 'rls' AS section,p.name,p.is_enabled,pr.predicate_definition FROM sys.security_policies p JOIN sys.security_predicates pr ON p.object_id=pr.object_id;
SELECT 'price_variation' AS section,COUNT(*) AS sold_products,
 SUM(CASE WHEN price_count>1 THEN 1 ELSE 0 END) AS products_multiple_prices,
 SUM(CASE WHEN cost_count>1 THEN 1 ELSE 0 END) AS products_multiple_implied_costs,
 MIN(price_count) AS min_price_count,MAX(price_count) AS max_price_count
FROM (SELECT StockItemID,COUNT(DISTINCT UnitPrice) AS price_count,
 COUNT(DISTINCT CAST((ExtendedPrice-TaxAmount-LineProfit)/NULLIF(Quantity,0) AS decimal(18,4))) AS cost_count
 FROM Sales.InvoiceLines GROUP BY StockItemID) q OPTION (MAX_GRANT_PERCENT=1);
SELECT 'product_price_details' AS section,StockItemID,COUNT(DISTINCT UnitPrice) AS prices,MIN(UnitPrice) AS min_price,MAX(UnitPrice) AS max_price,
 COUNT(DISTINCT PackageTypeID) AS packages FROM Sales.InvoiceLines GROUP BY StockItemID HAVING COUNT(DISTINCT UnitPrice)>1 OPTION (MAX_GRANT_PERCENT=1);
SELECT 'special_deals' AS section,SpecialDealID,StockItemID,CustomerID,BuyingGroupID,CustomerCategoryID,StockGroupID,DealDescription,StartDate,EndDate,DiscountAmount,DiscountPercentage,UnitPrice FROM Sales.SpecialDeals;
SELECT 'temporal_customer_changes' AS section,COUNT(DISTINCT a.CustomerID) AS archived_customers,
COUNT(DISTINCT CASE WHEN a.DeliveryCityID<>c.DeliveryCityID THEN a.CustomerID END) AS changed_delivery_city,
COUNT(DISTINCT CASE WHEN a.CustomerCategoryID<>c.CustomerCategoryID THEN a.CustomerID END) AS changed_category,
COUNT(DISTINCT CASE WHEN ISNULL(a.BuyingGroupID,-1)<>ISNULL(c.BuyingGroupID,-1) THEN a.CustomerID END) AS changed_buying_group
FROM Sales.Customers_Archive a JOIN Sales.Customers c ON a.CustomerID=c.CustomerID;
SELECT 'temporal_coverage' AS section,'Customers' AS entity,MIN(ValidFrom) AS earliest_valid_from,MAX(CASE WHEN ValidTo<'9999-01-01' THEN ValidTo END) AS last_closed_valid_to FROM Sales.Customers FOR SYSTEM_TIME ALL
UNION ALL SELECT 'temporal_coverage','StockItems',MIN(ValidFrom),MAX(CASE WHEN ValidTo<'9999-01-01' THEN ValidTo END) FROM Warehouse.StockItems FOR SYSTEM_TIME ALL;
SELECT 'unusual_colors' AS section,ColorID,ColorName FROM Warehouse.Colors WHERE ColorName IN ('NULL','Unknown','N/A','');
SELECT 'geography_population' AS section,SUM(CASE WHEN LatestRecordedPopulation IS NULL THEN 1 ELSE 0 END) AS cities_missing_population,COUNT(*) AS all_reference_cities FROM Application.Cities;
SELECT 'invoice_boundary' AS section,MIN(InvoiceDate) AS first_date,MAX(InvoiceDate) AS last_date,MIN(LastEditedWhen) AS first_lastedit,MAX(LastEditedWhen) AS last_lastedit FROM Sales.Invoices;
SELECT 'order_line_join_risk' AS section,SUM(CAST(il.n AS bigint)*ol.n) AS naive_join_rows,SUM(il.n) AS invoice_lines_matched FROM
 (SELECT i.OrderID,COUNT(*) n FROM Sales.Invoices i JOIN Sales.InvoiceLines l ON i.InvoiceID=l.InvoiceID GROUP BY i.OrderID) il
 JOIN (SELECT OrderID,COUNT(*) n FROM Sales.OrderLines GROUP BY OrderID) ol ON il.OrderID=ol.OrderID OPTION (MAX_GRANT_PERCENT=1);
SELECT 'product_attributes' AS section,Brand,COUNT(*) AS products FROM Warehouse.StockItems GROUP BY Brand;
SELECT 'customer_billing' AS section,COUNT(DISTINCT CustomerID) AS buying_customers,COUNT(DISTINCT BillToCustomerID) AS billing_customers FROM Sales.Invoices OPTION (MAX_GRANT_PERCENT=1);
-- Exact PK audit for all core entities (including bridge surrogate key).
CREATE TABLE #PK(table_name nvarchar(260),total_rows bigint,distinct_pk bigint,null_pk bigint);
DECLARE @sql nvarchar(max)='';
SELECT @sql=@sql+N'INSERT #PK SELECT N'''+SCHEMA_NAME(t.schema_id)+N'.'+t.name+N''',COUNT_BIG(*),COUNT_BIG(DISTINCT '+QUOTENAME(c.name)+N'),COUNT_BIG(*)-COUNT_BIG('+QUOTENAME(c.name)+N') FROM '+QUOTENAME(SCHEMA_NAME(t.schema_id))+N'.'+QUOTENAME(t.name)+N';'
FROM sys.tables t JOIN sys.indexes i ON t.object_id=i.object_id AND i.is_primary_key=1 JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
WHERE t.temporal_type<>1 AND ((SCHEMA_NAME(t.schema_id)='Sales' AND t.name IN ('Invoices','InvoiceLines','Customers','CustomerCategories','BuyingGroups','Orders','OrderLines','CustomerTransactions')) OR (SCHEMA_NAME(t.schema_id)='Warehouse' AND t.name IN ('StockItems','StockGroups','StockItemStockGroups','StockItemHoldings','PackageTypes')) OR (SCHEMA_NAME(t.schema_id)='Application' AND t.name IN ('Cities','StateProvinces','Countries','People')));
EXEC sys.sp_executesql @sql;
SELECT 'pk_actual' AS section,* FROM #PK ORDER BY table_name;
