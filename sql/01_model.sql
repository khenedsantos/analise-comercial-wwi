-- Etapa 4. Only analytics objects are created; source tables are read-only.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF SCHEMA_ID('analytics') IS NOT NULL THROW 51000,'analytics already exists. Use validation mode; no implicit rebuild.',1;
IF (SELECT COUNT_BIG(*) FROM Sales.InvoiceLines)<>228265
 OR (SELECT COUNT(*) FROM Sales.Invoices)<>70510
 OR EXISTS(SELECT 1 FROM Sales.Invoices WHERE IsCreditNote<>0 OR InvoiceDate<'20130101' OR InvoiceDate>'20160531')
 THROW 51000,'Snapshot outside contract. Stop and review.',1;
BEGIN TRANSACTION;
EXEC('CREATE SCHEMA analytics AUTHORIZATION dbo');

SELECT DISTINCT c.DeliveryCityID AS CityID,ct.CityName,sp.StateProvinceID,
 sp.StateProvinceCode,sp.StateProvinceName,co.CountryID,co.CountryName
INTO analytics.DimGeography
FROM Sales.Customers c JOIN Application.Cities ct ON ct.CityID=c.DeliveryCityID
JOIN Application.StateProvinces sp ON sp.StateProvinceID=ct.StateProvinceID
JOIN Application.Countries co ON co.CountryID=sp.CountryID;
ALTER TABLE analytics.DimGeography ADD CONSTRAINT PK_DimGeography PRIMARY KEY(CityID);

SELECT c.CustomerID,c.CustomerName,c.CustomerCategoryID,cc.CustomerCategoryName,
 c.BuyingGroupID,bg.BuyingGroupName,c.DeliveryCityID
INTO analytics.DimBuyer FROM Sales.Customers c
JOIN Sales.CustomerCategories cc ON cc.CustomerCategoryID=c.CustomerCategoryID
LEFT JOIN Sales.BuyingGroups bg ON bg.BuyingGroupID=c.BuyingGroupID;
ALTER TABLE analytics.DimBuyer ADD CONSTRAINT PK_DimBuyer PRIMARY KEY(CustomerID);
-- Geography is a fact dimension; this attribute records the buyer snapshot for lineage.
ALTER TABLE analytics.DimBuyer ADD CONSTRAINT FK_BuyerCity FOREIGN KEY(DeliveryCityID) REFERENCES analytics.DimGeography(CityID);

SELECT DISTINCT i.BillToCustomerID,c.CustomerName AS BillingAccountName
INTO analytics.DimBillingAccount FROM Sales.Invoices i
JOIN Sales.Customers c ON c.CustomerID=i.BillToCustomerID;
ALTER TABLE analytics.DimBillingAccount ADD CONSTRAINT PK_DimBillingAccount PRIMARY KEY(BillToCustomerID);

SELECT s.StockItemID,s.StockItemName,s.Brand,s.Size,s.ColorID,c.ColorName,
 s.UnitPackageID,p.PackageTypeName AS UnitPackageName
INTO analytics.DimProduct FROM Warehouse.StockItems s
LEFT JOIN Warehouse.Colors c ON c.ColorID=s.ColorID
JOIN Warehouse.PackageTypes p ON p.PackageTypeID=s.UnitPackageID;
ALTER TABLE analytics.DimProduct ADD CONSTRAINT PK_DimProduct PRIMARY KEY(StockItemID);
SELECT StockGroupID,StockGroupName INTO analytics.DimStockGroup FROM Warehouse.StockGroups;
ALTER TABLE analytics.DimStockGroup ADD CONSTRAINT PK_DimStockGroup PRIMARY KEY(StockGroupID);
SELECT StockItemID,StockGroupID INTO analytics.BridgeProductGroup FROM Warehouse.StockItemStockGroups;
ALTER TABLE analytics.BridgeProductGroup ADD CONSTRAINT PK_BridgeProductGroup PRIMARY KEY(StockItemID,StockGroupID),
 CONSTRAINT FK_BridgeProduct FOREIGN KEY(StockItemID) REFERENCES analytics.DimProduct(StockItemID),
 CONSTRAINT FK_BridgeGroup FOREIGN KEY(StockGroupID) REFERENCES analytics.DimStockGroup(StockGroupID);
CREATE INDEX IX_BridgeGroup ON analytics.BridgeProductGroup(StockGroupID,StockItemID);

SELECT SpecialDealID,DealDescription,BuyingGroupID,StockGroupID,StartDate,EndDate,DiscountPercentage
INTO analytics.DimSpecialDeal FROM Sales.SpecialDeals;
ALTER TABLE analytics.DimSpecialDeal ADD CONSTRAINT PK_DimSpecialDeal PRIMARY KEY(SpecialDealID);

CREATE TABLE analytics.DimDate(
 DateKey int NOT NULL PRIMARY KEY,CalendarDate date NOT NULL UNIQUE,
 CalendarYear smallint NOT NULL,MonthNumber tinyint NOT NULL,YearMonth int NOT NULL,
 MonthStart date NOT NULL,MonthEnd date NOT NULL,DayOfMonth tinyint NOT NULL,
 IsoDayOfWeek tinyint NOT NULL,IsCompleteYear bit NOT NULL);
WITH days AS (SELECT CAST('20130101' AS date) d UNION ALL SELECT DATEADD(day,1,d) FROM days WHERE d<'20160531')
INSERT analytics.DimDate SELECT YEAR(d)*10000+MONTH(d)*100+DAY(d),d,YEAR(d),MONTH(d),YEAR(d)*100+MONTH(d),
 DATEFROMPARTS(YEAR(d),MONTH(d),1),EOMONTH(d),DAY(d),1+DATEDIFF(day,'19000101',d)%7,
 CASE WHEN YEAR(d)<2016 THEN 1 ELSE 0 END FROM days OPTION(MAXRECURSION 0);

-- Historical eligibility, not an inference from negative profit or invoice date.
SELECT l.InvoiceLineID,d.SpecialDealID,
 CAST(ROUND(s.UnitPrice*d.DiscountPercentage/100.0,2) AS decimal(18,2)) ExpectedPrice
INTO #eligible
FROM Sales.InvoiceLines l JOIN Sales.Invoices i ON i.InvoiceID=l.InvoiceID
JOIN Sales.Orders o ON o.OrderID=i.OrderID JOIN Sales.Customers c ON c.CustomerID=i.CustomerID
JOIN Warehouse.StockItems FOR SYSTEM_TIME ALL s ON s.StockItemID=l.StockItemID
 AND CAST(o.OrderDate AS datetime2)>=s.ValidFrom AND CAST(o.OrderDate AS datetime2)<s.ValidTo
JOIN Warehouse.StockItemStockGroups b ON b.StockItemID=l.StockItemID
JOIN Sales.SpecialDeals d ON d.StockGroupID=b.StockGroupID AND d.BuyingGroupID=c.BuyingGroupID
 AND o.OrderDate BETWEEN d.StartDate AND d.EndDate OPTION(MAX_GRANT_PERCENT=1,MAXDOP 1);
IF EXISTS(SELECT InvoiceLineID FROM #eligible GROUP BY InvoiceLineID HAVING COUNT(*)<>1)
 THROW 51000,'Ambiguous historical deal eligibility.',1;
IF (SELECT COUNT(*) FROM #eligible)<>512 OR EXISTS(SELECT 1 FROM #eligible e JOIN Sales.InvoiceLines l ON l.InvoiceLineID=e.InvoiceLineID WHERE l.UnitPrice<>e.ExpectedPrice)
 THROW 51000,'Special price eligibility differs from approved snapshot.',1;
CREATE UNIQUE CLUSTERED INDEX IX_Eligible ON #eligible(InvoiceLineID);

SELECT l.InvoiceLineID,l.InvoiceID,i.OrderID,o.OrderDate,
 YEAR(i.InvoiceDate)*10000+MONTH(i.InvoiceDate)*100+DAY(i.InvoiceDate) AS DateKey,
 i.CustomerID,i.BillToCustomerID,l.StockItemID,c.DeliveryCityID AS CityID,
 l.PackageTypeID,l.Quantity,l.UnitPrice,l.TaxRate,l.TaxAmount,l.ExtendedPrice,l.LineProfit,
 CAST(l.ExtendedPrice-l.TaxAmount AS decimal(18,2)) AS SalesExTax,
 CAST(CASE WHEN l.LineProfit<0 THEN 1 ELSE 0 END AS bit) AS IsNegative,
 CAST(CASE WHEN e.SpecialDealID IS NOT NULL THEN 1 ELSE 0 END AS bit) AS IsSpecial,e.SpecialDealID
INTO analytics.FactInvoiceLine
FROM Sales.InvoiceLines l JOIN Sales.Invoices i ON i.InvoiceID=l.InvoiceID
JOIN Sales.Orders o ON o.OrderID=i.OrderID JOIN Sales.Customers c ON c.CustomerID=i.CustomerID
LEFT JOIN #eligible e ON e.InvoiceLineID=l.InvoiceLineID
OPTION(MAX_GRANT_PERCENT=1,MAXDOP 1);
ALTER TABLE analytics.FactInvoiceLine ALTER COLUMN DateKey int NOT NULL;
ALTER TABLE analytics.FactInvoiceLine ADD CONSTRAINT PK_FactInvoiceLine PRIMARY KEY(InvoiceLineID),
 CONSTRAINT FK_FactDate FOREIGN KEY(DateKey) REFERENCES analytics.DimDate(DateKey),
 CONSTRAINT FK_FactBuyer FOREIGN KEY(CustomerID) REFERENCES analytics.DimBuyer(CustomerID),
 CONSTRAINT FK_FactBilling FOREIGN KEY(BillToCustomerID) REFERENCES analytics.DimBillingAccount(BillToCustomerID),
 CONSTRAINT FK_FactProduct FOREIGN KEY(StockItemID) REFERENCES analytics.DimProduct(StockItemID),
 CONSTRAINT FK_FactCity FOREIGN KEY(CityID) REFERENCES analytics.DimGeography(CityID),
 CONSTRAINT FK_FactDeal FOREIGN KEY(SpecialDealID) REFERENCES analytics.DimSpecialDeal(SpecialDealID),
 CONSTRAINT CK_FactFlags CHECK(IsNegative=CASE WHEN LineProfit<0 THEN 1 ELSE 0 END AND IsSpecial=CASE WHEN SpecialDealID IS NULL THEN 0 ELSE 1 END),
 CONSTRAINT CK_FactMoney CHECK(SalesExTax+TaxAmount=ExtendedPrice);
CREATE INDEX IX_FactDate ON analytics.FactInvoiceLine(DateKey);
IF (SELECT COUNT_BIG(*) FROM analytics.FactInvoiceLine)<>228265 THROW 51000,'Load lost or duplicated rows.',1;
COMMIT;
