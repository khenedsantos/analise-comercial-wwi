SET NOCOUNT ON;
GO
CREATE OR ALTER FUNCTION analytics.SafeRatio(@n decimal(28,8),@d decimal(28,8))
RETURNS decimal(28,12) AS
BEGIN
 RETURN CASE WHEN @d>0 THEN CAST(@n/@d AS decimal(28,12)) END;
END;
GO
-- Filters are explicit JSON arrays of IDs; empty arrays mean no restriction.
-- StockGroups use EXISTS: no invoice line can be multiplied by bridge matches.
CREATE OR ALTER FUNCTION analytics.SelectedLines(@filters nvarchar(max))
RETURNS TABLE AS RETURN
 SELECT f.* FROM analytics.FactInvoiceLine f JOIN analytics.DimBuyer c ON c.CustomerID=f.CustomerID
 WHERE (NOT EXISTS(SELECT 1 FROM OPENJSON(@filters,'$.buyers')) OR f.CustomerID IN(SELECT CAST(value AS int) FROM OPENJSON(@filters,'$.buyers')))
 AND (NOT EXISTS(SELECT 1 FROM OPENJSON(@filters,'$.bills')) OR f.BillToCustomerID IN(SELECT CAST(value AS int) FROM OPENJSON(@filters,'$.bills')))
 AND (NOT EXISTS(SELECT 1 FROM OPENJSON(@filters,'$.products')) OR f.StockItemID IN(SELECT CAST(value AS int) FROM OPENJSON(@filters,'$.products')))
 AND (NOT EXISTS(SELECT 1 FROM OPENJSON(@filters,'$.cities')) OR f.CityID IN(SELECT CAST(value AS int) FROM OPENJSON(@filters,'$.cities')))
 AND (NOT EXISTS(SELECT 1 FROM OPENJSON(@filters,'$.categories')) OR c.CustomerCategoryID IN(SELECT CAST(value AS int) FROM OPENJSON(@filters,'$.categories')))
 AND (NOT EXISTS(SELECT 1 FROM OPENJSON(@filters,'$.buyingGroups')) OR EXISTS(SELECT 1 FROM OPENJSON(@filters,'$.buyingGroups') j WHERE CAST(j.value AS int)=c.BuyingGroupID OR (j.type=0 AND c.BuyingGroupID IS NULL)))
 AND (NOT EXISTS(SELECT 1 FROM OPENJSON(@filters,'$.stockGroups')) OR EXISTS(SELECT 1 FROM analytics.BridgeProductGroup b JOIN OPENJSON(@filters,'$.stockGroups') j ON b.StockGroupID=CAST(j.value AS int) WHERE b.StockItemID=f.StockItemID))
 AND (JSON_VALUE(@filters,'$.negative') IS NULL OR f.IsNegative=CAST(JSON_VALUE(@filters,'$.negative') AS bit))
 AND (JSON_VALUE(@filters,'$.special') IS NULL OR f.IsSpecial=CAST(JSON_VALUE(@filters,'$.special') AS bit));
GO
CREATE OR ALTER PROCEDURE analytics.Kpis
 @Start date='20130101',@End date='20160531',@Filters nvarchar(max)=N'{}',
 @Axis varchar(16)='buyer',@MemberID int=NULL,@Comparison varchar(8)='AUTO',@Dates nvarchar(max)=NULL
AS
BEGIN
 SET NOCOUNT ON;
 IF ISJSON(@Filters)<>1 OR LEFT(LTRIM(@Filters),1)<>'{' THROW 51000,'Filters must be a JSON object.',1;
 IF @Start IS NULL OR @End IS NULL OR @Start>@End THROW 51000,'Invalid date bounds.',1;
 IF @Axis NOT IN('buyer','bill','product','group','city','category','buyingGroup') THROW 51000,'Unknown axis.',1;
 IF @Comparison NOT IN('AUTO','YOY','MOM','YTD','NONE') THROW 51000,'Unknown comparison.',1;
 IF EXISTS(SELECT 1 FROM OPENJSON(@Filters) WHERE [key] NOT IN('buyers','bills','products','cities','categories','buyingGroups','stockGroups','negative','special')) THROW 51000,'Unknown filter; refusing silent omission.',1;
 IF EXISTS(SELECT 1 FROM OPENJSON(@Filters) WHERE [key] NOT IN('negative','special') AND type<>4) THROW 51000,'ID filters must be arrays.',1;
 IF EXISTS(SELECT 1 FROM OPENJSON(@Filters) WHERE [key] IN('negative','special') AND (type<>2 OR value NOT IN('0','1'))) THROW 51000,'Diagnostic flags must be 0 or 1.',1;
 IF EXISTS(SELECT 1 FROM OPENJSON(@Filters) a CROSS APPLY OPENJSON(CASE WHEN a.type=4 THEN a.value ELSE '[]' END) v WHERE (v.type<>2 OR TRY_CAST(v.value AS int) IS NULL) AND NOT(a.[key]='buyingGroups' AND v.type=0)) THROW 51000,'Invalid ID in filter.',1;
 DECLARE @days TABLE(d date PRIMARY KEY);
 IF @Dates IS NOT NULL BEGIN
  IF ISJSON(@Dates)<>1 OR LEFT(LTRIM(@Dates),1)<>'[' THROW 51000,'Dates must be a JSON array.',1;
  IF EXISTS(SELECT 1 FROM OPENJSON(@Dates) WHERE TRY_CONVERT(date,value,23) IS NULL) THROW 51000,'Invalid date list.',1;
  INSERT @days SELECT DISTINCT CONVERT(date,value,23) FROM OPENJSON(@Dates);
  IF NOT EXISTS(SELECT 1 FROM @days) OR EXISTS(SELECT 1 FROM @days WHERE d<@Start OR d>@End) THROW 51000,'Date list must be nonempty and within bounds.',1;
 END;
 DECLARE @covered bit=CASE WHEN @Start>='20130101' AND @End<='20160531' THEN 1 ELSE 0 END,
 @complete bit=CASE WHEN DAY(@Start)=1 AND @End=EOMONTH(@End) THEN 1 ELSE 0 END,
 @p0 date=NULL,@p1 date=NULL,@mode varchar(8)=@Comparison;
 IF @Dates IS NOT NULL AND (SELECT COUNT(*) FROM @days)<>DATEDIFF(day,@Start,@End)+1 SET @complete=0;
 IF @mode='AUTO' SET @mode=CASE WHEN EOMONTH(@Start)=@End THEN 'YOY' WHEN MONTH(@Start)=1 AND YEAR(@Start)=YEAR(@End) THEN 'YTD' ELSE 'NONE' END;
 IF @covered=1 AND @complete=1 BEGIN
  IF @mode='MOM' AND EOMONTH(@Start)=@End SELECT @p0=DATEADD(month,-1,@Start),@p1=EOMONTH(@Start,-1);
  IF @mode='YOY' AND (EOMONTH(@Start)=@End OR (MONTH(@Start)=1 AND MONTH(@End)=12 AND YEAR(@Start)=YEAR(@End)))
   SELECT @p0=DATEADD(year,-1,@Start),@p1=EOMONTH(DATEADD(year,-1,@End));
  IF @mode='YTD' AND MONTH(@Start)=1 AND YEAR(@Start)=YEAR(@End)
   SELECT @p0=DATEADD(year,-1,@Start),@p1=EOMONTH(DATEADD(year,-1,@End));
 END;
 IF @p0<'20130101' OR @p1>'20160531' SELECT @p0=NULL,@p1=NULL;
 -- Materialize only the selected current/prior rows, once, for the 21 metrics.
 SELECT f.*,c.CustomerCategoryID,c.BuyingGroupID,
 CAST(CASE WHEN d.CalendarDate BETWEEN @Start AND @End AND (@Dates IS NULL OR EXISTS(SELECT 1 FROM @days x WHERE x.d=d.CalendarDate)) THEN 1 ELSE 0 END AS bit) IsCurrent
 INTO #s FROM analytics.SelectedLines(@Filters) f
 JOIN analytics.DimDate d ON d.DateKey=f.DateKey JOIN analytics.DimBuyer c ON c.CustomerID=f.CustomerID
 WHERE @covered=1 AND ((d.CalendarDate BETWEEN @Start AND @End AND (@Dates IS NULL OR EXISTS(SELECT 1 FROM @days x WHERE x.d=d.CalendarDate))) OR d.CalendarDate BETWEEN @p0 AND @p1)
 OPTION(RECOMPILE,MAX_GRANT_PERCENT=1,MAXDOP 1);
 DECLARE @sv decimal(28,2)=(SELECT COALESCE(SUM(SalesExTax),0) FROM #s WHERE IsCurrent=1),@top decimal(28,2)=NULL;
 IF @Axis IN('buyer','bill','product') BEGIN
  WITH totals AS(SELECT CASE @Axis WHEN 'buyer' THEN CustomerID WHEN 'bill' THEN BillToCustomerID ELSE StockItemID END EntityID,SUM(SalesExTax) Revenue FROM #s WHERE IsCurrent=1
   GROUP BY CASE @Axis WHEN 'buyer' THEN CustomerID WHEN 'bill' THEN BillToCustomerID ELSE StockItemID END),
  ranked AS(SELECT *,ROW_NUMBER() OVER(ORDER BY Revenue DESC,EntityID ASC) rn FROM totals)
  SELECT @top=SUM(Revenue) FROM ranked WHERE rn<=5 OPTION(MAX_GRANT_PERCENT=1);
 END;
 -- Add only the visual member here; S and its ranking above keep external selections.
 SELECT * INTO #f FROM #s s WHERE @MemberID IS NULL
 OR (@Axis='buyer' AND CustomerID=@MemberID) OR (@Axis='bill' AND BillToCustomerID=@MemberID)
 OR (@Axis='product' AND StockItemID=@MemberID) OR (@Axis='city' AND CityID=@MemberID)
 OR (@Axis='category' AND CustomerCategoryID=@MemberID) OR (@Axis='buyingGroup' AND BuyingGroupID=@MemberID)
 OR (@Axis='group' AND EXISTS(SELECT 1 FROM analytics.BridgeProductGroup b WHERE b.StockItemID=s.StockItemID AND b.StockGroupID=@MemberID)) OPTION(RECOMPILE,MAX_GRANT_PERCENT=1);
 DECLARE @v decimal(28,2),@t decimal(28,2),@b decimal(28,2),@l decimal(28,2),@n bigint,@i bigint,@c bigint,@a bigint,@q bigint,
 @neg bigint,@nl decimal(28,2),@sp bigint,@spv decimal(28,2),@pv decimal(28,2),@pl decimal(28,2);
 SELECT @v=COALESCE(SUM(SalesExTax),0),@t=COALESCE(SUM(TaxAmount),0),@b=COALESCE(SUM(ExtendedPrice),0),@l=COALESCE(SUM(LineProfit),0),
 @n=COUNT_BIG(*),@i=COUNT(DISTINCT InvoiceID),@c=COUNT(DISTINCT CustomerID),@a=COUNT(DISTINCT BillToCustomerID),@q=COUNT(DISTINCT StockItemID),
 @neg=COALESCE(SUM(CAST(IsNegative AS bigint)),0),@nl=COALESCE(SUM(CASE WHEN IsNegative=1 THEN LineProfit ELSE 0 END),0),
 @sp=COALESCE(SUM(CAST(IsSpecial AS bigint)),0),@spv=COALESCE(SUM(CASE WHEN IsSpecial=1 THEN SalesExTax ELSE 0 END),0)
 FROM #f WHERE IsCurrent=1 OPTION(MAX_GRANT_PERCENT=1);
 SELECT @pv=COALESCE(SUM(SalesExTax),0),@pl=COALESCE(SUM(LineProfit),0) FROM #f WHERE IsCurrent=0;
 SELECT m.MetricID,CAST(CASE WHEN @covered=1 THEN m.Value END AS decimal(38,10)) AS Value,
 @Start AS PeriodStart,@End AS PeriodEnd,@p0 AS PriorStart,@p1 AS PriorEnd,@mode AS ComparisonMode,
 @Filters AS FiltersJson,@Dates AS DatesJson,@Axis AS Axis,@MemberID AS MemberID,
 CAST('UM; ratios in percent; K16 in percentage points; counts in units' AS nvarchar(150)) AS Units,
 CAST('Synthetic Microsoft WWI; buyer geography/category even on billing axis; special prices use base*percentage/100, not conventional discount.' AS nvarchar(250)) AS Caveat,
 CAST(CASE WHEN @Axis='bill' THEN 'billing account; buyer attributes' ELSE 'buyer (CustomerID); billing separate' END AS nvarchar(100)) AS CustomerRole,
 CAST(CASE WHEN @MemberID IS NOT NULL OR EXISTS(SELECT 1 FROM OPENJSON(@Filters,'$.products')) OR EXISTS(SELECT 1 FROM OPENJSON(@Filters,'$.stockGroups')) THEN 'valor medio do recorte por fatura' ELSE 'ticket medio por fatura' END AS nvarchar(100)) AS TicketLabel,
 CAST(CASE WHEN @Axis='group' THEN 'overlapping groups; percentages not additive' ELSE 'exclusive axis or total' END AS nvarchar(100)) AS GroupWarning,
 CAST('contrato_analitico_etapa3.md v1.0; P0; official backup SHA256 066279a8cd28c8d85cbd8215ea71a5d672b420cfbc19756b635c27bd8027dada' AS nvarchar(200)) AS Lineage
 FROM (VALUES
 ('K01',CAST(@v AS decimal(38,10))),('K02',@t),('K03',@b),('K04',@l),('K05',100*analytics.SafeRatio(@l,@v)),
 ('K06',@i),('K07',@c),('K08',@a),('K09',@q),('K10',analytics.SafeRatio(@v,@i)),
 ('K11',100*analytics.SafeRatio(@v,@sv)),('K12',100*analytics.SafeRatio(@top,@sv)),
 ('K13',CASE WHEN @p0 IS NOT NULL THEN @v-@pv END),('K14',CASE WHEN @p0 IS NOT NULL THEN 100*analytics.SafeRatio(@v-@pv,@pv) END),
 ('K15',CASE WHEN @p0 IS NOT NULL THEN @l-@pl END),('K16',CASE WHEN @p0 IS NOT NULL THEN 100*(analytics.SafeRatio(@l,@v)-analytics.SafeRatio(@pl,@pv)) END),
 ('K17',@neg),('K18',100*analytics.SafeRatio(@neg,@n)),('K19',@nl),('K20',@sp),('K21',100*analytics.SafeRatio(@spv,@v))
 ) m(MetricID,Value) ORDER BY m.MetricID;
END;
GO
-- Dense civil months make LAG(1)/LAG(12) calendar comparisons, not prior sales rows.
-- This view is unfiltered control support; filtered comparisons use Kpis.
CREATE OR ALTER VIEW analytics.MonthlyControl AS
 WITH amounts AS(SELECT DateKey,SUM(SalesExTax) Revenue,SUM(LineProfit) Profit FROM analytics.FactInvoiceLine GROUP BY DateKey),
 months AS(SELECT d.YearMonth,MIN(d.CalendarDate) PeriodStart,MAX(d.CalendarDate) PeriodEnd,
 COALESCE(SUM(a.Revenue),0) Revenue,COALESCE(SUM(a.Profit),0) Profit
 FROM analytics.DimDate d LEFT JOIN amounts a ON a.DateKey=d.DateKey GROUP BY d.YearMonth)
 SELECT *,LAG(Revenue,1) OVER(ORDER BY YearMonth) PriorMonthRevenue,
 LAG(Revenue,12) OVER(ORDER BY YearMonth) PriorYearRevenue FROM months;
