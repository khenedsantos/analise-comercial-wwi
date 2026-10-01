SET NOCOUNT ON;
SELECT 'source_functions' AS section,OBJECT_SCHEMA_NAME(object_id) AS schema_name,OBJECT_NAME(object_id) AS object_name,definition
FROM sys.sql_modules WHERE object_id IN (OBJECT_ID('Website.CalculateCustomerPrice'),OBJECT_ID('Application.DetermineCustomerAccess'));
SELECT 'standard_discount' AS section,StandardDiscountPercentage,COUNT(*) AS customers FROM Sales.Customers GROUP BY StandardDiscountPercentage;
SELECT 'low_price_vs_deal' AS section,d.SpecialDealID,d.DiscountPercentage,COUNT_BIG(*) AS lines,COUNT(DISTINCT l.StockItemID) AS products,
 MIN(o.OrderDate) AS first_order,MAX(o.OrderDate) AS last_order,
 SUM(CASE WHEN l.UnitPrice=ROUND(s.UnitPrice*d.DiscountPercentage/100.0,2) THEN 1 ELSE 0 END) AS price_equals_percentage_of_base,
 SUM(CASE WHEN l.UnitPrice=ROUND(s.UnitPrice*(1-d.DiscountPercentage/100.0),2) THEN 1 ELSE 0 END) AS price_equals_base_minus_percentage,
 SUM(CASE WHEN l.LineProfit<0 THEN 1 ELSE 0 END) AS negative_profit_lines
FROM Sales.InvoiceLines l JOIN Sales.Invoices i ON l.InvoiceID=i.InvoiceID JOIN Sales.Orders o ON i.OrderID=o.OrderID
JOIN Sales.Customers c ON i.CustomerID=c.CustomerID JOIN Warehouse.StockItems FOR SYSTEM_TIME ALL s ON l.StockItemID=s.StockItemID AND CAST(o.OrderDate AS datetime2)>=s.ValidFrom AND CAST(o.OrderDate AS datetime2)<s.ValidTo
JOIN Warehouse.StockItemStockGroups b ON l.StockItemID=b.StockItemID
JOIN Sales.SpecialDeals d ON b.StockGroupID=d.StockGroupID AND c.BuyingGroupID=d.BuyingGroupID AND o.OrderDate BETWEEN d.StartDate AND d.EndDate
GROUP BY d.SpecialDealID,d.DiscountPercentage OPTION (MAX_GRANT_PERCENT=1);
SELECT 'low_price_temporal_coverage' AS section,COUNT_BIG(*) AS joined_lines,COUNT(DISTINCT l.InvoiceLineID) AS distinct_lines,
SUM(CASE WHEN s.StockItemID IS NULL THEN 1 ELSE 0 END) AS no_historical_product,
SUM(CASE WHEN l.UnitPrice<s.UnitPrice THEN 1 ELSE 0 END) AS below_historical_list
FROM Sales.InvoiceLines l JOIN Sales.Invoices i ON l.InvoiceID=i.InvoiceID JOIN Sales.Orders o ON i.OrderID=o.OrderID
LEFT JOIN Warehouse.StockItems FOR SYSTEM_TIME ALL s ON l.StockItemID=s.StockItemID AND CAST(o.OrderDate AS datetime2)>=s.ValidFrom AND CAST(o.OrderDate AS datetime2)<s.ValidTo OPTION (MAX_GRANT_PERCENT=1);
