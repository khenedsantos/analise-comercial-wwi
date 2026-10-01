SET NOCOUNT ON;
CREATE TABLE #checks(ContractID varchar(3),TestName nvarchar(180),Actual nvarchar(300),Expected nvarchar(300),Passed bit);
GO
CREATE PROCEDURE #Check @id varchar(3),@name nvarchar(180),@actual decimal(38,10),@expected decimal(38,10)
AS INSERT #checks SELECT @id,@name,CONVERT(nvarchar(100),@actual),CONVERT(nvarchar(100),@expected),
 CASE WHEN @actual=@expected OR (@actual IS NULL AND @expected IS NULL) THEN 1 ELSE 0 END;
DECLARE @msg nvarchar(200)=@id+N' '+@name; RAISERROR(@msg,0,1) WITH NOWAIT;
GO
DECLARE @x decimal(38,10);
SELECT @x=COUNT(*) FROM (SELECT InvoiceLineID FROM Sales.InvoiceLines EXCEPT SELECT InvoiceLineID FROM analytics.FactInvoiceLine) a OPTION(MAX_GRANT_PERCENT=1);
EXEC #Check 'C01','Source IDs missing from fact',@x,0;
SELECT @x=COUNT(*) FROM (SELECT InvoiceLineID FROM analytics.FactInvoiceLine EXCEPT SELECT InvoiceLineID FROM Sales.InvoiceLines) a OPTION(MAX_GRANT_PERCENT=1);
EXEC #Check 'C01','Additional fact IDs',@x,0;
SELECT @x=COUNT_BIG(*) FROM analytics.FactInvoiceLine; EXEC #Check 'C02','Fact rows',@x,228265;
SELECT @x=COUNT(DISTINCT InvoiceLineID) FROM analytics.FactInvoiceLine OPTION(MAX_GRANT_PERCENT=1); EXEC #Check 'C02','Distinct original IDs',@x,228265;
SELECT @x=COUNT(DISTINCT InvoiceID) FROM analytics.FactInvoiceLine OPTION(MAX_GRANT_PERCENT=1); EXEC #Check 'C02','Distinct invoices',@x,70510;
SELECT @x=COUNT(*) FROM analytics.FactInvoiceLine WHERE InvoiceLineID IS NULL; EXEC #Check 'C02','Null grain',@x,0;
SELECT @x=COUNT(*) FROM(SELECT InvoiceID FROM analytics.FactInvoiceLine GROUP BY InvoiceID HAVING COUNT(DISTINCT CustomerID)>1 OR COUNT(DISTINCT BillToCustomerID)>1 OR COUNT(DISTINCT DateKey)>1 OR COUNT(DISTINCT OrderID)>1) q OPTION(MAX_GRANT_PERCENT=1);
EXEC #Check 'C02','Header consistency',@x,0;
SELECT @x=COUNT(*) FROM analytics.FactInvoiceLine f JOIN Sales.InvoiceLines l ON l.InvoiceLineID=f.InvoiceLineID JOIN Sales.Invoices i ON i.InvoiceID=l.InvoiceID WHERE f.InvoiceID<>i.InvoiceID OR f.OrderID<>i.OrderID OR f.CustomerID<>i.CustomerID OR f.BillToCustomerID<>i.BillToCustomerID OR f.StockItemID<>l.StockItemID OPTION(MAX_GRANT_PERCENT=1);
EXEC #Check 'C02','Source header and item keys (no OrderID-only item join)',@x,0;
SELECT @x=COUNT_BIG(*) FROM analytics.FactInvoiceLine f JOIN analytics.DimDate d ON d.DateKey=f.DateKey JOIN analytics.DimBuyer c ON c.CustomerID=f.CustomerID JOIN analytics.DimBillingAccount a ON a.BillToCustomerID=f.BillToCustomerID JOIN analytics.DimProduct p ON p.StockItemID=f.StockItemID JOIN analytics.DimGeography g ON g.CityID=f.CityID LEFT JOIN analytics.DimSpecialDeal s ON s.SpecialDealID=f.SpecialDealID OPTION(MAX_GRANT_PERCENT=1);
EXEC #Check 'C03','Full dimensional joins preserve all lines',@x,228265;
SELECT @x=COUNT(*) FROM sys.foreign_keys WHERE schema_id=SCHEMA_ID('analytics') AND (is_disabled=1 OR is_not_trusted=1); EXEC #Check 'C03','Untrusted or disabled FKs',@x,0;
GO
DECLARE @x decimal(38,10);
SELECT l.InvoiceLineID,s.StockItemID,s.UnitPrice HistoricalPrice INTO #history
FROM Sales.InvoiceLines l JOIN Sales.Invoices i ON i.InvoiceID=l.InvoiceID JOIN Sales.Orders o ON o.OrderID=i.OrderID
LEFT JOIN Warehouse.StockItems FOR SYSTEM_TIME ALL s ON s.StockItemID=l.StockItemID AND CAST(o.OrderDate AS datetime2)>=s.ValidFrom AND CAST(o.OrderDate AS datetime2)<s.ValidTo OPTION(MAX_GRANT_PERCENT=1,MAXDOP 1);
SELECT @x=COUNT_BIG(*) FROM #history; EXEC #Check 'C03','Temporal product cardinality',@x,228265;
SELECT @x=COUNT(*) FROM #history WHERE StockItemID IS NULL; EXEC #Check 'C03','Missing temporal product versions',@x,0;
SELECT i.InvoiceID,c.CustomerID,c.DeliveryCityID,c.CustomerCategoryID,c.BuyingGroupID INTO #customerHistory FROM Sales.Invoices i
LEFT JOIN Sales.Customers FOR SYSTEM_TIME ALL c ON c.CustomerID=i.CustomerID AND CAST(i.InvoiceDate AS datetime2)>=c.ValidFrom AND CAST(i.InvoiceDate AS datetime2)<c.ValidTo OPTION(LOOP JOIN,MAX_GRANT_PERCENT=1,MAXDOP 1);
SELECT @x=COUNT(*) FROM #customerHistory; EXEC #Check 'C03','Temporal buyer cardinality',@x,70510;
SELECT @x=COUNT(*) FROM #customerHistory WHERE CustomerID IS NULL; EXEC #Check 'C03','Missing temporal buyer versions',@x,0;
GO
DECLARE @x decimal(38,10);
SELECT @x=SUM(SalesExTax) FROM analytics.FactInvoiceLine; EXEC #Check 'C04','Net sales exact cents',@x,172261341.20;
SELECT @x=SUM(TaxAmount) FROM analytics.FactInvoiceLine; EXEC #Check 'C04','Tax exact cents',@x,25782098.25;
SELECT @x=SUM(ExtendedPrice) FROM analytics.FactInvoiceLine; EXEC #Check 'C04','Gross sales exact cents',@x,198043439.45;
SELECT @x=SUM(LineProfit) FROM analytics.FactInvoiceLine; EXEC #Check 'C04','Recorded profit exact cents',@x,85729180.90;
SELECT @x=COUNT(*) FROM(SELECT InvoiceID FROM analytics.FactInvoiceLine GROUP BY InvoiceID HAVING SUM(SalesExTax)+SUM(TaxAmount)<>SUM(ExtendedPrice)) a OPTION(MAX_GRANT_PERCENT=1); EXEC #Check 'C04','Invoice financial identities',@x,0;
SELECT @x=COUNT(*) FROM(SELECT DateKey/100 ym FROM analytics.FactInvoiceLine GROUP BY DateKey/100 HAVING SUM(SalesExTax)+SUM(TaxAmount)<>SUM(ExtendedPrice)) a; EXEC #Check 'C04','Month financial identities',@x,0;
SELECT @x=COUNT(*) FROM(SELECT StockItemID FROM analytics.FactInvoiceLine GROUP BY StockItemID HAVING SUM(SalesExTax)+SUM(TaxAmount)<>SUM(ExtendedPrice)) a; EXEC #Check 'C04','Product financial identities',@x,0;
SELECT @x=COUNT(*) FROM analytics.FactInvoiceLine f JOIN Sales.InvoiceLines l ON l.InvoiceLineID=f.InvoiceLineID WHERE f.Quantity<>l.Quantity OR f.UnitPrice<>l.UnitPrice OR f.TaxRate<>l.TaxRate OR f.TaxAmount<>l.TaxAmount OR f.ExtendedPrice<>l.ExtendedPrice OR f.LineProfit<>l.LineProfit OR f.SalesExTax<>ROUND(f.Quantity*f.UnitPrice,2) OR f.TaxAmount<>ROUND(f.Quantity*f.UnitPrice*f.TaxRate/100,2) OPTION(MAX_GRANT_PERCENT=1);
EXEC #Check 'C05','All original financial fields and source formulas',@x,0;
SELECT @x=COUNT(*) FROM analytics.FactInvoiceLine f JOIN Warehouse.StockItemHoldings h ON h.StockItemID=f.StockItemID WHERE f.LineProfit<>ROUND(f.Quantity*(f.UnitPrice-h.LastCostPrice),2) OPTION(MAX_GRANT_PERCENT=1);
EXEC #Check 'C05','Snapshot cost reference only; no replacement',@x,0;
SELECT @x=analytics.SafeRatio(10,0); EXEC #Check 'C06','Zero denominator helper',@x,NULL;
SELECT @x=analytics.SafeRatio(10,-2); EXEC #Check 'C06','Negative denominator helper',@x,NULL;
SELECT @x=CASE WHEN ABS(AVG(100*analytics.SafeRatio(LineProfit,SalesExTax))-100*analytics.SafeRatio(SUM(LineProfit),SUM(SalesExTax)))>0.0001 THEN 1 ELSE 0 END FROM analytics.FactInvoiceLine;
EXEC #Check 'C06','Unweighted mean differs from required margin',@x,1;
GO
DECLARE @x decimal(38,10);
SELECT @x=COUNT(*) FROM analytics.FactInvoiceLine WHERE IsNegative=1; EXEC #Check 'C07','Negative lines',@x,4626;
SELECT @x=SUM(LineProfit) FROM analytics.FactInvoiceLine WHERE IsNegative=1; EXEC #Check 'C07','Signed negative profit',@x,-320493.55;
SELECT @x=COUNT(*) FROM analytics.FactInvoiceLine WHERE IsNegative<>CASE WHEN LineProfit<0 THEN 1 ELSE 0 END; EXEC #Check 'C07','Negative flag equivalence',@x,0;
SELECT f.InvoiceLineID,d.SpecialDealID INTO #expectedDeals FROM analytics.FactInvoiceLine f
JOIN #history h ON h.InvoiceLineID=f.InvoiceLineID JOIN Sales.Customers c ON c.CustomerID=f.CustomerID
JOIN Warehouse.StockItemStockGroups b ON b.StockItemID=f.StockItemID
JOIN Sales.SpecialDeals d ON d.StockGroupID=b.StockGroupID AND d.BuyingGroupID=c.BuyingGroupID AND f.OrderDate BETWEEN d.StartDate AND d.EndDate
WHERE f.UnitPrice=ROUND(h.HistoricalPrice*d.DiscountPercentage/100,2) OPTION(MAX_GRANT_PERCENT=1);
SELECT @x=COUNT(*) FROM #expectedDeals; EXEC #Check 'C08','Independent historical eligibility count',@x,512;
SELECT @x=COUNT(*) FROM(SELECT InvoiceLineID,SpecialDealID FROM #expectedDeals EXCEPT SELECT InvoiceLineID,SpecialDealID FROM analytics.FactInvoiceLine WHERE IsSpecial=1) a; EXEC #Check 'C08','Expected special association missing',@x,0;
SELECT @x=COUNT(*) FROM(SELECT InvoiceLineID,SpecialDealID FROM analytics.FactInvoiceLine WHERE IsSpecial=1 EXCEPT SELECT InvoiceLineID,SpecialDealID FROM #expectedDeals) a; EXEC #Check 'C08','Unexpected special association',@x,0;
SELECT @x=COUNT(*) FROM analytics.FactInvoiceLine WHERE SpecialDealID=1; EXEC #Check 'C08','Agreement 1',@x,301;
SELECT @x=COUNT(*) FROM analytics.FactInvoiceLine WHERE SpecialDealID=2; EXEC #Check 'C08','Agreement 2',@x,211;
SELECT @x=COUNT(*) FROM analytics.FactInvoiceLine WHERE IsSpecial=1 AND IsNegative=0; EXEC #Check 'C08','Special outside negative set',@x,0;
SELECT @x=COUNT(*) FROM analytics.FactInvoiceLine WHERE IsNegative=1 AND IsSpecial=0; EXEC #Check 'C08','Negative non-special',@x,4114;
SELECT @x=COUNT(*) FROM Sales.Invoices WHERE IsCreditNote<>0; EXEC #Check 'C09','Observed credits',@x,0;
SELECT @x=COUNT(*) FROM analytics.DimBuyer; EXEC #Check 'C10','Buyer dimension',@x,663;
SELECT @x=COUNT(*) FROM analytics.DimBillingAccount; EXEC #Check 'C10','Billing dimension',@x,263;
SELECT @x=COUNT(*) FROM analytics.FactInvoiceLine f JOIN Sales.Invoices i ON i.InvoiceID=f.InvoiceID WHERE f.CustomerID<>i.CustomerID OR f.BillToCustomerID<>i.BillToCustomerID OPTION(MAX_GRANT_PERCENT=1); EXEC #Check 'C10','Invoice customer roles preserved',@x,0;
SELECT @x=COUNT(*) FROM analytics.DimProduct; EXEC #Check 'C11','Products',@x,227;
SELECT @x=COUNT(*) FROM analytics.BridgeProductGroup; EXEC #Check 'C11','Bridge pairs',@x,442;
SELECT @x=COUNT(*) FROM(SELECT StockItemID FROM analytics.BridgeProductGroup GROUP BY StockItemID HAVING COUNT(*)=1) a; EXEC #Check 'C11','One group',@x,94;
SELECT @x=COUNT(*) FROM(SELECT StockItemID FROM analytics.BridgeProductGroup GROUP BY StockItemID HAVING COUNT(*)=2) a; EXEC #Check 'C11','Two groups',@x,51;
SELECT @x=COUNT(*) FROM(SELECT StockItemID FROM analytics.BridgeProductGroup GROUP BY StockItemID HAVING COUNT(*)=3) a; EXEC #Check 'C11','Three groups',@x,82;
SELECT @x=COUNT(*) FROM analytics.DimProduct p WHERE NOT EXISTS(SELECT 1 FROM analytics.BridgeProductGroup b WHERE b.StockItemID=p.StockItemID); EXEC #Check 'C11','Ungrouped products',@x,0;
SELECT @x=COUNT(*) FROM analytics.SelectedLines(N'{"stockGroups":[1,2,3,4,5,6,7,8,9,10]}'); EXEC #Check 'C11','All groups union restores P0',@x,228265;

GO
DECLARE @x decimal(38,10);
-- Exhaustive 45 group pairs: real API filter sums versus independent product sets.
SELECT StockItemID,COUNT_BIG(*) N,SUM(SalesExTax) V,SUM(TaxAmount) T,SUM(ExtendedPrice) B,SUM(LineProfit) L INTO #productAmounts FROM analytics.FactInvoiceLine GROUP BY StockItemID;
DECLARE @ga int,@gb int,@filter nvarchar(max),@fail int=0,@pairs int=0;
DECLARE pairs CURSOR LOCAL FAST_FORWARD FOR SELECT a.StockGroupID,b.StockGroupID FROM analytics.DimStockGroup a CROSS JOIN analytics.DimStockGroup b WHERE a.StockGroupID<b.StockGroupID;
OPEN pairs; FETCH NEXT FROM pairs INTO @ga,@gb;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @filter=N'{"stockGroups":['+CONVERT(nvarchar(10),@ga)+','+CONVERT(nvarchar(10),@gb)+']}';
 DECLARE @an bigint,@av decimal(28,2),@at decimal(28,2),@ab decimal(28,2),@al decimal(28,2),@en bigint,@ev decimal(28,2),@et decimal(28,2),@eb decimal(28,2),@el decimal(28,2);
 SELECT @an=COUNT_BIG(*),@av=COALESCE(SUM(SalesExTax),0),@at=COALESCE(SUM(TaxAmount),0),@ab=COALESCE(SUM(ExtendedPrice),0),@al=COALESCE(SUM(LineProfit),0) FROM analytics.SelectedLines(@filter) OPTION(RECOMPILE,MAX_GRANT_PERCENT=1);
 SELECT @en=COALESCE(SUM(N),0),@ev=COALESCE(SUM(V),0),@et=COALESCE(SUM(T),0),@eb=COALESCE(SUM(B),0),@el=COALESCE(SUM(L),0) FROM #productAmounts p WHERE EXISTS(SELECT 1 FROM analytics.BridgeProductGroup b WHERE b.StockItemID=p.StockItemID AND b.StockGroupID IN(@ga,@gb));
 IF @an<>@en OR @av<>@ev OR @at<>@et OR @ab<>@eb OR @al<>@el SET @fail+=1;
 -- Inclusion-exclusion, independent product-level membership indicators.
 SELECT @en=COALESCE(SUM(p.N*(a.y+b.y-a.y*b.y)),0),@ev=COALESCE(SUM(p.V*(a.y+b.y-a.y*b.y)),0),@et=COALESCE(SUM(p.T*(a.y+b.y-a.y*b.y)),0),@eb=COALESCE(SUM(p.B*(a.y+b.y-a.y*b.y)),0),@el=COALESCE(SUM(p.L*(a.y+b.y-a.y*b.y)),0)
 FROM #productAmounts p CROSS APPLY(SELECT CASE WHEN EXISTS(SELECT 1 FROM analytics.BridgeProductGroup x WHERE x.StockItemID=p.StockItemID AND x.StockGroupID=@ga) THEN 1 ELSE 0 END y) a
 CROSS APPLY(SELECT CASE WHEN EXISTS(SELECT 1 FROM analytics.BridgeProductGroup x WHERE x.StockItemID=p.StockItemID AND x.StockGroupID=@gb) THEN 1 ELSE 0 END y) b;
 IF @an<>@en OR @av<>@ev OR @at<>@et OR @ab<>@eb OR @al<>@el SET @fail+=1;
 SET @pairs+=1; FETCH NEXT FROM pairs INTO @ga,@gb;
END;
CLOSE pairs; DEALLOCATE pairs;
EXEC #Check 'C12','Exhaustive pairs executed',@pairs,45;
EXEC #Check 'C12','Union and inclusion-exclusion mismatches (count and four sums)',@fail,0;
-- Compute bad-join sentinels via per-product multiplicities, no giant join.
SELECT @x=SUM(p.N*g.n) FROM #productAmounts p JOIN(SELECT StockItemID,COUNT(*) n FROM analytics.BridgeProductGroup GROUP BY StockItemID) g ON g.StockItemID=p.StockItemID;
EXEC #Check 'C12','Deliberately wrong join row sentinel detected',@x,450703;
SELECT @x=SUM(p.V*g.n) FROM #productAmounts p JOIN(SELECT StockItemID,COUNT(*) n FROM analytics.BridgeProductGroup GROUP BY StockItemID) g ON g.StockItemID=p.StockItemID;
EXEC #Check 'C12','Deliberately wrong join revenue sentinel detected',@x,275964455.10;
GO
DECLARE @x decimal(38,10);
SELECT @x=COUNT(*) FROM analytics.DimDate; EXEC #Check 'C15','Civil calendar days',@x,1247;
SELECT @x=COUNT(DISTINCT YearMonth) FROM analytics.DimDate; EXEC #Check 'C15','Civil calendar months',@x,41;
SELECT @x=COUNT(*) FROM(SELECT CalendarYear FROM analytics.DimDate GROUP BY CalendarYear HAVING COUNT(DISTINCT MonthNumber)<>CASE WHEN CalendarYear=2016 THEN 5 ELSE 12 END) a; EXEC #Check 'C15','Full years and 2016 YTD coverage',@x,0;
SELECT @x=COUNT(*) FROM analytics.DimDate WHERE CalendarDate='20160229'; EXEC #Check 'C16','Leap day retained',@x,1;
SELECT @x=COUNT(*) FROM analytics.DimDate WHERE CalendarDate<'20130101' OR CalendarDate>'20160531'; EXEC #Check 'C15','No calendar dates outside coverage',@x,0;
SELECT @x=COUNT(*) FROM analytics.DimBuyer WHERE BuyingGroupID IS NULL; EXEC #Check 'C17','Null buying groups preserved',@x,261;
SELECT @x=COUNT(*) FROM analytics.DimBuyer WHERE CustomerCategoryID IS NULL; EXEC #Check 'C17','No missing customer categories',@x,0;
SELECT @x=COUNT(*) FROM #customerHistory h JOIN analytics.DimBuyer c ON c.CustomerID=h.CustomerID WHERE h.DeliveryCityID<>c.DeliveryCityID OR h.CustomerCategoryID<>c.CustomerCategoryID OR ISNULL(h.BuyingGroupID,-1)<>ISNULL(c.BuyingGroupID,-1);
EXEC #Check 'C17','Historical buyer attributes equal accepted current snapshot',@x,0;
SELECT @x=COUNT(*) FROM analytics.DimProduct WHERE Brand IS NULL; EXEC #Check 'C17','Optional missing brands retained',@x,209;
SELECT @x=COUNT(*) FROM analytics.FactInvoiceLine f JOIN analytics.DimBuyer c ON c.CustomerID=f.CustomerID WHERE f.CityID<>c.DeliveryCityID; EXEC #Check 'C17','Buyer delivery geography',@x,0;
-- Every partition reconciles all four monetary sums and line count.
DECLARE @part nvarchar(100),@sql nvarchar(max);
DECLARE parts CURSOR LOCAL FAST_FORWARD FOR SELECT x FROM(VALUES('DateKey/100'),('StockItemID'),('CustomerID'),('BillToCustomerID'),('IsNegative'),('IsSpecial'),('IsNegative,IsSpecial')) a(x);
OPEN parts; FETCH NEXT FROM parts INTO @part;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @sql=N'INSERT #checks SELECT ''C18'',''Partition '+@part+''',CAST(SUM(n) AS nvarchar(100)),''228265 and four exact totals'',CASE WHEN SUM(n)=228265 AND SUM(v)=172261341.20 AND SUM(t)=25782098.25 AND SUM(b)=198043439.45 AND SUM(l)=85729180.90 THEN 1 ELSE 0 END FROM(SELECT COUNT_BIG(*) n,SUM(SalesExTax) v,SUM(TaxAmount) t,SUM(ExtendedPrice) b,SUM(LineProfit) l FROM analytics.FactInvoiceLine GROUP BY '+@part+N') a OPTION(MAX_GRANT_PERCENT=1);';
 EXEC sys.sp_executesql @sql; FETCH NEXT FROM parts INTO @part;
END; CLOSE parts; DEALLOCATE parts;
GO
-- Real stored-procedure executions; fixtures below are not WWI transactions.
CREATE TABLE #m(MetricID varchar(3),Value decimal(38,10),PeriodStart date,PeriodEnd date,PriorStart date,PriorEnd date,ComparisonMode varchar(8),FiltersJson nvarchar(max),DatesJson nvarchar(max),Axis varchar(16),MemberID int,Units nvarchar(150),Caveat nvarchar(250),CustomerRole nvarchar(100),TicketLabel nvarchar(100),GroupWarning nvarchar(100),Lineage nvarchar(200));
CREATE TABLE #observed(CaseName varchar(50),MetricID varchar(3),Value decimal(38,10),PriorStart date,PriorEnd date);
INSERT #m EXEC analytics.Kpis;
INSERT #observed SELECT 'baseline',MetricID,Value,PriorStart,PriorEnd FROM #m;
DECLARE @x decimal(38,10);
SELECT @x=COUNT(*) FROM #m; EXEC #Check 'C19','All 21 metric IDs returned',@x,21;
SELECT @x=COUNT(*) FROM #m WHERE PeriodStart IS NULL OR PeriodEnd IS NULL OR FiltersJson IS NULL OR CustomerRole IS NULL OR Units NOT LIKE 'UM%' OR Caveat NOT LIKE 'Synthetic%' OR Caveat NOT LIKE '%base*percentage%' OR Lineage NOT LIKE '%v1.0%'; EXEC #Check 'C19','Context and lineage on every metric',@x,0;
SELECT @x=Value FROM #m WHERE MetricID='K01'; EXEC #Check 'C04','K01 API',@x,172261341.20;
SELECT @x=Value FROM #m WHERE MetricID='K02'; EXEC #Check 'C04','K02 API',@x,25782098.25;
SELECT @x=Value FROM #m WHERE MetricID='K03'; EXEC #Check 'C04','K03 API',@x,198043439.45;
SELECT @x=Value FROM #m WHERE MetricID='K04'; EXEC #Check 'C04','K04 API',@x,85729180.90;
SELECT @x=ROUND(Value,4) FROM #m WHERE MetricID='K05'; EXEC #Check 'C06','K05 display',@x,49.7669;
SELECT @x=Value FROM #m WHERE MetricID='K06'; EXEC #Check 'C14','K06 distinct invoices',@x,70510;
SELECT @x=Value FROM #m WHERE MetricID='K07'; EXEC #Check 'C10','K07 buyers',@x,663;
SELECT @x=Value FROM #m WHERE MetricID='K08'; EXEC #Check 'C10','K08 billing',@x,263;
SELECT @x=Value FROM #m WHERE MetricID='K09'; EXEC #Check 'C14','K09 products',@x,227;
SELECT @x=Value FROM #m WHERE MetricID='K17'; EXEC #Check 'C07','K17',@x,4626;
SELECT @x=Value FROM #m WHERE MetricID='K19'; EXEC #Check 'C07','K19 signed',@x,-320493.55;
SELECT @x=Value FROM #m WHERE MetricID='K20'; EXEC #Check 'C08','K20',@x,512;
-- Decimal ratios tested before display rounding at API scale (10 decimals).
DECLARE @expected decimal(38,10);
SELECT @x=Value FROM #m WHERE MetricID='K05'; SET @expected=100*analytics.SafeRatio(85729180.90,172261341.20); EXEC #Check 'C06','K05 ratio before display',@x,@expected;
SELECT @x=Value FROM #m WHERE MetricID='K10'; SET @expected=analytics.SafeRatio(172261341.20,70510); EXEC #Check 'C14','K10 baseline',@x,@expected;
SELECT @x=Value FROM #m WHERE MetricID='K18'; SET @expected=100*analytics.SafeRatio(4626,228265); EXEC #Check 'C07','K18 exact API precision',@x,@expected;
SELECT @expected=100*analytics.SafeRatio(SUM(CASE WHEN IsSpecial=1 THEN SalesExTax ELSE 0 END),SUM(SalesExTax)) FROM analytics.FactInvoiceLine;
SELECT @x=Value FROM #m WHERE MetricID='K21'; EXEC #Check 'C08','K21 special revenue denominator',@x,@expected;
GO

CREATE TABLE #scenarios(Name varchar(50),StartDate date,EndDate date,Filters nvarchar(max),Axis varchar(16),MemberID int,Comparison varchar(8),Dates nvarchar(max),SourcePredicate nvarchar(max));
INSERT #scenarios VALUES
(N'selected_products',N'20130101',N'20160531',N'{"products":[1,2,3,4,5,6]}',N'product',N'1',N'NONE',NULL,N'l.StockItemID IN(1,2,3,4,5,6)'),
(N'selected_buyers',N'20130101',N'20160531',N'{"buyers":[1,2,3,4,5,6,7,8]}',N'buyer',N'1',N'NONE',NULL,N'i.CustomerID IN(1,2,3,4,5,6,7,8)'),
(N'billing_axis',N'20130101',N'20160531',N'{}',N'bill',NULL,N'NONE',NULL,N'1=1'),
(N'product_axis',N'20130101',N'20160531',N'{}',N'product',NULL,N'NONE',NULL,N'1=1'),
(N'partial_basket',N'20130101',N'20160531',N'{"products":[1]}',N'product',NULL,N'NONE',NULL,N'l.StockItemID=1'),
(N'negative_only',N'20130101',N'20160531',N'{"negative":1}',N'buyer',NULL,N'NONE',NULL,N'l.LineProfit<0'),
(N'special_only',N'20130101',N'20160531',N'{"special":1}',N'buyer',NULL,N'NONE',NULL,N'EXISTS(SELECT 1 FROM #expectedDeals e WHERE e.InvoiceLineID=l.InvoiceLineID)'),
(N'non_special_positive',N'20160101',N'20160531',N'{"special":0,"negative":0}',N'buyer',NULL,N'AUTO',NULL,N'l.LineProfit>=0 AND NOT EXISTS(SELECT 1 FROM #expectedDeals e WHERE e.InvoiceLineID=l.InvoiceLineID)'),
(N'empty_group',N'20130101',N'20160531',N'{"stockGroups":[5]}',N'group',N'5',N'NONE',NULL,N'EXISTS(SELECT 1 FROM Warehouse.StockItemStockGroups b WHERE b.StockItemID=l.StockItemID AND b.StockGroupID=5)'),
(N'no_group_selection',N'20160101',N'20160531',N'{"stockGroups":[]}',N'buyer',NULL,N'AUTO',NULL,N'1=1'),
(N'group_union',N'20130101',N'20160531',N'{"stockGroups":[7,8]}',N'group',N'7',N'NONE',NULL,N'EXISTS(SELECT 1 FROM Warehouse.StockItemStockGroups b WHERE b.StockItemID=l.StockItemID AND b.StockGroupID IN(7,8))'),
(N'group_product_intersection',N'20130101',N'20160531',N'{"stockGroups":[7,8],"products":[1,2,3]}',N'product',NULL,N'NONE',NULL,N'l.StockItemID IN(1,2,3) AND EXISTS(SELECT 1 FROM Warehouse.StockItemStockGroups b WHERE b.StockItemID=l.StockItemID AND b.StockGroupID IN(7,8))'),
(N'outside',N'20160601',N'20160630',N'{}',N'buyer',NULL,N'AUTO',NULL,N'1=1'),
(N'sunday',N'20130106',N'20130106',N'{}',N'buyer',NULL,N'AUTO',NULL,N'1=1'),
(N'first_mom',N'20130101',N'20130131',N'{}',N'buyer',NULL,N'MOM',NULL,N'1=1'),
(N'first_yoy',N'20130101',N'20131231',N'{}',N'buyer',NULL,N'YOY',NULL,N'1=1'),
(N'leap_yoy',N'20160201',N'20160229',N'{}',N'buyer',NULL,N'AUTO',NULL,N'1=1'),
(N'ytd_2016',N'20160101',N'20160531',N'{}',N'buyer',NULL,N'AUTO',NULL,N'1=1'),
(N'annual_2014',N'20140101',N'20141231',N'{}',N'buyer',NULL,N'AUTO',NULL,N'1=1'),
(N'mom',N'20150501',N'20150531',N'{}',N'buyer',NULL,N'MOM',NULL,N'1=1'),
(N'partial_month',N'20160502',N'20160531',N'{}',N'buyer',NULL,N'AUTO',NULL,N'1=1'),
(N'discontinuous',N'20160501',N'20160531',N'{}',N'buyer',NULL,N'AUTO',N'["2016-05-01","2016-05-31"]',N'i.InvoiceDate IN(''20160501'',''20160531'')'),
(N'zero_base',N'20160101',N'20160531',N'{"stockGroups":[5]}',N'buyer',NULL,N'AUTO',NULL,N'EXISTS(SELECT 1 FROM Warehouse.StockItemStockGroups b WHERE b.StockItemID=l.StockItemID AND b.StockGroupID=5)'),
(N'buyer_bill_intersection',N'20130101',N'20160531',N'{"buyers":[1,2,3],"bills":[1]}',N'buyer',NULL,N'NONE',NULL,N'i.CustomerID IN(1,2,3) AND i.BillToCustomerID=1'),
(N'null_buying_group',N'20130101',N'20160531',N'{"buyingGroups":[null]}',N'buyer',NULL,N'NONE',NULL,N'c.BuyingGroupID IS NULL'),
(N'category_city',N'20130101',N'20160531',N'{"categories":[3],"cities":[19586]}',N'city',NULL,N'NONE',NULL,N'c.CustomerCategoryID=3 AND c.DeliveryCityID=19586');

DECLARE @name varchar(50),@start date,@end date,@filters nvarchar(max),@axis varchar(16),@member int,@cmp varchar(8),@dates nvarchar(max),@predicate nvarchar(max),@oracle nvarchar(max);
CREATE TABLE #oracle(InvoiceLineID int,InvoiceID int,CustomerID int,BillToCustomerID int,StockItemID int,CityID int,CategoryID int,BuyingGroupID int,V decimal(18,2),T decimal(18,2),B decimal(18,2),L decimal(18,2),Special bit);
DECLARE scenarios CURSOR LOCAL FAST_FORWARD FOR SELECT * FROM #scenarios;
OPEN scenarios; FETCH NEXT FROM scenarios INTO @name,@start,@end,@filters,@axis,@member,@cmp,@dates,@predicate;
WHILE @@FETCH_STATUS=0 BEGIN
 TRUNCATE TABLE #m; TRUNCATE TABLE #oracle;
 INSERT #m EXEC analytics.Kpis @Start=@start,@End=@end,@Filters=@filters,@Axis=@axis,@MemberID=@member,@Comparison=@cmp,@Dates=@dates;
 INSERT #observed SELECT @name,MetricID,Value,PriorStart,PriorEnd FROM #m;
 SET @oracle=N'INSERT #oracle SELECT l.InvoiceLineID,l.InvoiceID,i.CustomerID,i.BillToCustomerID,l.StockItemID,c.DeliveryCityID,c.CustomerCategoryID,c.BuyingGroupID,l.ExtendedPrice-l.TaxAmount,l.TaxAmount,l.ExtendedPrice,l.LineProfit,CASE WHEN EXISTS(SELECT 1 FROM #expectedDeals e WHERE e.InvoiceLineID=l.InvoiceLineID) THEN 1 ELSE 0 END FROM Sales.InvoiceLines l JOIN Sales.Invoices i ON i.InvoiceID=l.InvoiceID JOIN Sales.Customers c ON c.CustomerID=i.CustomerID WHERE i.InvoiceDate BETWEEN @s AND @e AND ('+@predicate+N') OPTION(MAX_GRANT_PERCENT=1);';
 EXEC sys.sp_executesql @oracle,N'@s date,@e date',@start,@end;
 DECLARE @sv decimal(28,2),@top decimal(28,2),@exp decimal(38,10),@actual decimal(38,10);
 SELECT @sv=COALESCE(SUM(V),0) FROM #oracle;
 -- Independent top-five aggregate on source S, before the visual member.
 SELECT @top=SUM(Revenue) FROM(SELECT TOP(5) SUM(V) Revenue,CASE @axis WHEN 'buyer' THEN CustomerID WHEN 'bill' THEN BillToCustomerID ELSE StockItemID END ID FROM #oracle GROUP BY CASE @axis WHEN 'buyer' THEN CustomerID WHEN 'bill' THEN BillToCustomerID ELSE StockItemID END ORDER BY Revenue DESC,ID ASC) a OPTION(MAX_GRANT_PERCENT=1);
 SET @exp=CASE WHEN @axis IN('buyer','bill','product') AND @start>='20130101' AND @end<='20160531' THEN 100*analytics.SafeRatio(@top,@sv) END;
 SELECT @actual=Value FROM #m WHERE MetricID='K12';
 INSERT #checks SELECT 'C13',@name+' K12 source ranking',CONVERT(nvarchar(100),@actual),CONVERT(nvarchar(100),@exp),CASE WHEN @actual=@exp OR(@actual IS NULL AND @exp IS NULL) THEN 1 ELSE 0 END;
 IF @member IS NOT NULL DELETE o FROM #oracle o WHERE NOT((@axis='buyer' AND CustomerID=@member) OR(@axis='bill' AND BillToCustomerID=@member) OR(@axis='product' AND StockItemID=@member) OR(@axis='city' AND CityID=@member) OR(@axis='category' AND CategoryID=@member) OR(@axis='buyingGroup' AND BuyingGroupID=@member) OR(@axis='group' AND EXISTS(SELECT 1 FROM Warehouse.StockItemStockGroups b WHERE b.StockItemID=o.StockItemID AND b.StockGroupID=@member)));
 DECLARE @v decimal(28,2),@t decimal(28,2),@b decimal(28,2),@l decimal(28,2),@n bigint,@i bigint,@c bigint,@bill bigint,@p bigint,@ng bigint,@nl decimal(28,2),@sp bigint,@spv decimal(28,2);
 SELECT @v=COALESCE(SUM(V),0),@t=COALESCE(SUM(T),0),@b=COALESCE(SUM(B),0),@l=COALESCE(SUM(L),0),@n=COUNT_BIG(*),@i=COUNT(DISTINCT InvoiceID),@c=COUNT(DISTINCT CustomerID),@bill=COUNT(DISTINCT BillToCustomerID),@p=COUNT(DISTINCT StockItemID),@ng=COALESCE(SUM(CASE WHEN L<0 THEN 1 ELSE 0 END),0),@nl=COALESCE(SUM(CASE WHEN L<0 THEN L ELSE 0 END),0),@sp=COALESCE(SUM(CAST(Special AS int)),0),@spv=COALESCE(SUM(CASE WHEN Special=1 THEN V ELSE 0 END),0) FROM #oracle OPTION(MAX_GRANT_PERCENT=1);
 INSERT #checks SELECT k.CID,@name+' '+k.ID+' vs original source',CONVERT(nvarchar(100),m.Value),CONVERT(nvarchar(100),e.Value),CASE WHEN m.Value=e.Value OR(m.Value IS NULL AND e.Value IS NULL) THEN 1 ELSE 0 END
 FROM(VALUES('K01','C04',CAST(@v AS decimal(38,10))),('K02','C04',@t),('K03','C04',@b),('K04','C04',@l),('K05','C06',100*analytics.SafeRatio(@l,@v)),('K06','C14',@i),('K07','C10',@c),('K08','C10',@bill),('K09','C14',@p),('K10','C14',analytics.SafeRatio(@v,@i)),('K11','C13',100*analytics.SafeRatio(@v,@sv)),('K17','C07',@ng),('K18','C07',100*analytics.SafeRatio(@ng,@n)),('K19','C07',@nl),('K20','C08',@sp),('K21','C08',100*analytics.SafeRatio(@spv,@v))) k(ID,CID,Value)
 CROSS APPLY(SELECT CASE WHEN @start>='20130101' AND @end<='20160531' THEN k.Value END Value) e JOIN #m m ON m.MetricID=k.ID;
 FETCH NEXT FROM scenarios INTO @name,@start,@end,@filters,@axis,@member,@cmp,@dates,@predicate;
END; CLOSE scenarios; DEALLOCATE scenarios;
GO
-- Explicit temporal oracle bounds, independent of Kpis period selection logic.
CREATE TABLE #periods(CaseName varchar(50),StartDate date,EndDate date,PriorStart date,PriorEnd date,EmptySet bit);
INSERT #periods VALUES('leap_yoy','20160201','20160229','20150201','20150228',0),('ytd_2016','20160101','20160531','20150101','20150531',0),('annual_2014','20140101','20141231','20130101','20131231',0),('mom','20150501','20150531','20150401','20150430',0),('zero_base','20160101','20160531','20150101','20150531',1);
DECLARE @name varchar(50),@s date,@e date,@p0 date,@p1 date,@empty bit,@v decimal(28,2),@l decimal(28,2),@pv decimal(28,2),@pl decimal(28,2);
DECLARE periods CURSOR LOCAL FAST_FORWARD FOR SELECT * FROM #periods;
OPEN periods; FETCH NEXT FROM periods INTO @name,@s,@e,@p0,@p1,@empty;
WHILE @@FETCH_STATUS=0 BEGIN
 SELECT @v=COALESCE(SUM(il.ExtendedPrice-il.TaxAmount),0),@l=COALESCE(SUM(il.LineProfit),0) FROM Sales.InvoiceLines il JOIN Sales.Invoices i ON i.InvoiceID=il.InvoiceID WHERE i.InvoiceDate BETWEEN @s AND @e AND @empty=0 OPTION(MAX_GRANT_PERCENT=1);
 SELECT @pv=COALESCE(SUM(il.ExtendedPrice-il.TaxAmount),0),@pl=COALESCE(SUM(il.LineProfit),0) FROM Sales.InvoiceLines il JOIN Sales.Invoices i ON i.InvoiceID=il.InvoiceID WHERE i.InvoiceDate BETWEEN @p0 AND @p1 AND @empty=0 OPTION(MAX_GRANT_PERCENT=1);
 INSERT #checks SELECT 'C16',@name+' '+o.MetricID,CONVERT(nvarchar(100),o.Value),CONVERT(nvarchar(100),x.Value),CASE WHEN (o.Value=x.Value OR(o.Value IS NULL AND x.Value IS NULL)) AND o.PriorStart=@p0 AND o.PriorEnd=@p1 THEN 1 ELSE 0 END
 FROM #observed o JOIN(VALUES('K13',CAST(@v-@pv AS decimal(38,10))),('K14',100*analytics.SafeRatio(@v-@pv,@pv)),('K15',@l-@pl),('K16',100*(analytics.SafeRatio(@l,@v)-analytics.SafeRatio(@pl,@pv)))) x(ID,Value) ON o.MetricID=x.ID WHERE o.CaseName=@name;
 FETCH NEXT FROM periods INTO @name,@s,@e,@p0,@p1,@empty;
END; CLOSE periods; DEALLOCATE periods;
DECLARE @x decimal(38,10);
SELECT @x=COUNT(*) FROM #observed WHERE CaseName IN('baseline','outside','sunday','first_mom','first_yoy','partial_month','discontinuous') AND MetricID IN('K13','K14','K15','K16') AND(Value IS NOT NULL OR PriorStart IS NOT NULL OR PriorEnd IS NOT NULL);
EXEC #Check 'C16','Unavailable, partial and discontinuous temporal comparisons',@x,0;
SELECT @x=COUNT(*) FROM #observed WHERE CaseName='outside' AND Value IS NOT NULL; EXEC #Check 'C15','Outside coverage: all 21 N/A',@x,0;
SELECT @x=Value FROM #observed WHERE CaseName='sunday' AND MetricID='K01'; EXEC #Check 'C15','Sunday inside coverage: zero sales',@x,0;
SELECT @x=Value FROM #observed WHERE CaseName='negative_only' AND MetricID='K18'; EXEC #Check 'C07','Explicit negative-only denominator retained',@x,100;
SELECT @x=Value FROM #observed WHERE CaseName='special_only' AND MetricID='K21'; EXEC #Check 'C08','Explicit special-only denominator retained',@x,100;
SELECT @x=Value FROM #observed WHERE CaseName='partial_basket' AND MetricID='K12'; EXEC #Check 'C13','Fewer than five selected products',@x,100;
SELECT @x=CASE WHEN (SELECT Value FROM #observed WHERE CaseName='partial_basket' AND MetricID='K01')<(SELECT SUM(l.ExtendedPrice-l.TaxAmount) FROM Sales.InvoiceLines l WHERE EXISTS(SELECT 1 FROM Sales.InvoiceLines p WHERE p.InvoiceID=l.InvoiceID AND p.StockItemID=1)) THEN 1 ELSE 0 END;
EXEC #Check 'C14','Partial item revenue does not retrieve entire baskets',@x,1;
SELECT @x=CASE WHEN SUM(n)>70510 THEN 1 ELSE 0 END FROM(SELECT StockItemID,COUNT(DISTINCT InvoiceID) n FROM analytics.FactInvoiceLine GROUP BY StockItemID) a OPTION(MAX_GRANT_PERCENT=1);
EXEC #Check 'C14','Invoice distinct counts not additive across products',@x,1;
SELECT @x=CASE WHEN SUM(n)>663 THEN 1 ELSE 0 END FROM(SELECT StockItemID,COUNT(DISTINCT CustomerID) n FROM analytics.FactInvoiceLine GROUP BY StockItemID) a OPTION(MAX_GRANT_PERCENT=1);
EXEC #Check 'C14','Buyer distinct counts not additive across products',@x,1;
SELECT @x=CASE WHEN SUM(n)>227 THEN 1 ELSE 0 END FROM(SELECT CustomerID,COUNT(DISTINCT StockItemID) n FROM analytics.FactInvoiceLine GROUP BY CustomerID) a OPTION(MAX_GRANT_PERCENT=1);
EXEC #Check 'C14','Product distinct counts not additive across buyers',@x,1;
-- Test-only fixture: six tied revenues; same ROW_NUMBER ordering as production.
WITH fixture AS(SELECT * FROM(VALUES(6,10),(4,10),(2,10),(5,10),(1,10),(3,10)) f(ID,Revenue)),ranked AS(SELECT *,ROW_NUMBER() OVER(ORDER BY Revenue DESC,ID ASC) rn FROM fixture)
SELECT @x=SUM(ID) FROM ranked WHERE rn<=5; EXEC #Check 'C13','TEST FIXTURE deterministic five-way tie boundary',@x,15;
SELECT @x=COUNT(*) FROM analytics.MonthlyControl WHERE (YearMonth=201301 AND PriorMonthRevenue IS NOT NULL) OR(YearMonth<201401 AND PriorYearRevenue IS NOT NULL); EXEC #Check 'C16','Dense month LAG coverage edges',@x,0;
SELECT @x=COUNT(*) FROM analytics.MonthlyControl m LEFT JOIN analytics.MonthlyControl p ON p.YearMonth=YEAR(DATEADD(month,-1,m.PeriodStart))*100+MONTH(DATEADD(month,-1,m.PeriodStart)) WHERE ISNULL(m.PriorMonthRevenue,-1)<>ISNULL(p.Revenue,-1) OPTION(MAX_GRANT_PERCENT=1); EXEC #Check 'C16','LAG MoM matches civil previous month for all 41 months',@x,0;
SELECT @x=COUNT(*) FROM analytics.MonthlyControl m LEFT JOIN analytics.MonthlyControl p ON p.YearMonth=m.YearMonth-100 WHERE ISNULL(m.PriorYearRevenue,-1)<>ISNULL(p.Revenue,-1) OPTION(MAX_GRANT_PERCENT=1); EXEC #Check 'C16','LAG YoY matches previous year for all 41 months',@x,0;
-- Input errors cannot silently remove an unknown filter or invent a comparison.
BEGIN TRY EXEC analytics.Kpis @Filters=N'{"unknown":[1]}'; EXEC #Check 'C13','Reject unknown filter',0,1; END TRY BEGIN CATCH EXEC #Check 'C13','Reject unknown filter',1,1; END CATCH;
BEGIN TRY EXEC analytics.Kpis @Filters=N'{"buyers":"1"}'; EXEC #Check 'C13','Reject malformed ID selection',0,1; END TRY BEGIN CATCH EXEC #Check 'C13','Reject malformed ID selection',1,1; END CATCH;
BEGIN TRY EXEC analytics.Kpis @Axis='invented'; EXEC #Check 'C13','Reject unknown axis',0,1; END TRY BEGIN CATCH EXEC #Check 'C13','Reject unknown axis',1,1; END CATCH;
SELECT ContractID,TestName,Actual,Expected,Passed FROM #checks ORDER BY ContractID,TestName;
SELECT CaseName,MetricID,Value,PriorStart,PriorEnd FROM #observed ORDER BY CaseName,MetricID;
