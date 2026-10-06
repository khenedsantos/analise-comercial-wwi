"""Generate the official PBIP/TMSL text model; no SQL connection or data copy.

Source of truth for this technical preparation. Desktop validation is separate.
Only Python standard library. Never modifies Stage 3/4 files.
"""
from pathlib import Path
import json
import uuid

ROOT = Path(__file__).resolve().parent
SM = ROOT / 'WWI.SemanticModel'
SCHEMA = 'https://developer.microsoft.com/json-schemas/fabric/'

def write(path, obj):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def tag(name):
    return str(uuid.uuid5(uuid.NAMESPACE_URL, 'wwi-portfolio/' + name))

# Exact source columns. i=int64, s=string, d=dateTime, b=boolean, m=fixed decimal.
spec = {
 'FactInvoiceLine': 'InvoiceLineID:i InvoiceID:i OrderID:i OrderDate:d DateKey:i CustomerID:i BillToCustomerID:i StockItemID:i CityID:i PackageTypeID:i Quantity:i UnitPrice:m TaxRate:m TaxAmount:m ExtendedPrice:m LineProfit:m SalesExTax:m IsNegative:b IsSpecial:b SpecialDealID:i',
 'DimDate': 'DateKey:i CalendarDate:d CalendarYear:i MonthNumber:i YearMonth:i MonthStart:d MonthEnd:d DayOfMonth:i IsoDayOfWeek:i IsCompleteYear:b',
 'DimBuyer': 'CustomerID:i CustomerName:s CustomerCategoryID:i CustomerCategoryName:s BuyingGroupID:i BuyingGroupName:s DeliveryCityID:i',
 'DimBillingAccount': 'BillToCustomerID:i BillingAccountName:s',
 'DimGeography': 'CityID:i CityName:s StateProvinceID:i StateProvinceCode:s StateProvinceName:s CountryID:i CountryName:s',
 'DimProduct': 'StockItemID:i StockItemName:s Brand:s Size:s ColorID:i ColorName:s UnitPackageID:i UnitPackageName:s',
 'DimStockGroup': 'StockGroupID:i StockGroupName:s',
 'BridgeProductGroup': 'StockItemID:i StockGroupID:i',
 'DimSpecialDeal': 'SpecialDealID:i DealDescription:s BuyingGroupID:i StockGroupID:i StartDate:d EndDate:d DiscountPercentage:m',
}
types = dict(i='int64', s='string', d='dateTime', b='boolean', m='decimal')
mtypes = dict(i='Int64.Type', s='type text', d='type date', b='type logical', m='Currency.Type')
tables = []
for name, fields in spec.items():
    columns, conversions = [], []
    for field in fields.split():
        col, typ = field.split(':')
        c = dict(name=col, dataType=types[typ], sourceColumn=col, summarizeBy='none', lineageTag=tag(name+'/'+col))
        c['isHidden'] = col.endswith('ID') or col == 'DateKey' or (name == 'FactInvoiceLine' and col not in ('IsNegative', 'IsSpecial'))
        if typ == 'd': c['formatString'] = 'dd/MM/yyyy'
        if typ == 'm': c['formatString'] = '#,0.00;-#,0.00;0.00'
        if name == 'DimDate' and col == 'CalendarDate':
            c.update(isKey=True, annotations=[dict(name='UnderlyingDateTimeDataType', value='Date')])
        columns.append(c)
        conversions.append('{"' + col + '", ' + mtypes[typ] + '}')
    expr = ['let', '    Source = Sql.Database("(localdb)\\WWI_Portfolio", "WWI_Portfolio_Diagnostic", [CreateNavigationProperties=false]),',
            f'    Data = Source{{[Schema="analytics",Item="{name}"]}}[Data],',
            '    Typed = Table.TransformColumnTypes(Data, {' + ', '.join(conversions) + '})', 'in', '    Typed']
    t = dict(name=name, lineageTag=tag(name), columns=columns,
             partitions=[dict(name=name, mode='import', source=dict(type='m', expression=expr))])
    if name == 'DimDate': t['dataCategory'] = 'Time'
    if name == 'BridgeProductGroup': t['isHidden'] = True
    tables.append(t)

relationships = []
def rel(ft, fc, tt, tc, both=False):
    relationships.append(dict(name=tag(ft+'/'+fc+'->'+tt+'/'+tc), fromTable=ft, fromColumn=fc,
        toTable=tt, toColumn=tc, fromCardinality='many', toCardinality='one', isActive=True,
        crossFilteringBehavior='bothDirections' if both else 'oneDirection'))
for t, c in [('DimDate','DateKey'),('DimBuyer','CustomerID'),('DimBillingAccount','BillToCustomerID'),
             ('DimGeography','CityID'),('DimProduct','StockItemID'),('DimSpecialDeal','SpecialDealID')]:
    rel('FactInvoiceLine', c, t, c)
rel('BridgeProductGroup','StockGroupID','DimStockGroup','StockGroupID')
rel('BridgeProductGroup','StockItemID','DimProduct','StockItemID',True)

measures = []
MONEY = '#,0.00;-#,0.00;0.00'
PCT = '0.0000%;-0.0000%;0.0000%'
def measure(name, dax, fmt=MONEY, folder='01 â€” Financeiro', hidden=False, desc=None):
    measures.append(dict(name=name, expression=dax.strip().splitlines(), formatString=fmt,
        displayFolder=folder, isHidden=hidden, lineageTag=tag('_Medidas/'+name),
        description=desc or 'WWI sintÃ©tica. Contrato Etapa 3; respeita os filtros do recorte.'))

measure('_Cobertura', '''VAR n = COUNTROWS(VALUES(DimDate[CalendarDate]))
RETURN n > 0 && MIN(DimDate[CalendarDate]) >= DATE(2013,1,1) && MAX(DimDate[CalendarDate]) <= DATE(2016,5,31)''', 'TRUE;TRUE;FALSE', hidden=True)
for name, col in [('Vendas sem impostos','SalesExTax'), ('Impostos','TaxAmount'),
                  ('Faturamento com impostos','ExtendedPrice'), ('Lucro comercial registrado','LineProfit')]:
    measure(name, f'IF([_Cobertura], COALESCE(SUM(FactInvoiceLine[{col}]),0))')
measure('Margem comercial registrada','IF([Vendas sem impostos] > 0, DIVIDE([Lucro comercial registrado],[Vendas sem impostos]))',PCT)
measure('Linhas faturadas','IF([_Cobertura], COALESCE(COUNTROWS(FactInvoiceLine),0))','#,0','02 â€” Volume')
for name,col in [('Faturas','InvoiceID'),('Clientes compradores','CustomerID'),('Contas de cobranÃ§a','BillToCustomerID'),('Produtos faturados','StockItemID')]:
    measure(name,f'IF([_Cobertura], COALESCE(DISTINCTCOUNT(FactInvoiceLine[{col}]),0))','#,0','02 â€” Volume')
measure('Valor mÃ©dio do recorte por fatura','IF([Faturas] > 0, DIVIDE(CONVERT([Vendas sem impostos], DOUBLE),[Faturas]))',desc='K10. Sob produto/grupo, valor das linhas selecionadas por fatura, nÃ£o da cesta inteira.')
measure('Linhas de lucro negativo','CALCULATE([Linhas faturadas], KEEPFILTERS(FactInvoiceLine[IsNegative] = TRUE()))','#,0','05 â€” DiagnÃ³sticos')
measure('Resultado registrado das linhas negativas','CALCULATE([Lucro comercial registrado], KEEPFILTERS(FactInvoiceLine[IsNegative] = TRUE()))',folder='05 â€” DiagnÃ³sticos')
measure('Linhas em condiÃ§Ãµes especiais','CALCULATE([Linhas faturadas], KEEPFILTERS(FactInvoiceLine[IsSpecial] = TRUE()))','#,0','05 â€” DiagnÃ³sticos')
measure('Negativas nÃ£o especiais','CALCULATE([Linhas de lucro negativo], KEEPFILTERS(FactInvoiceLine[IsSpecial] = FALSE()))','#,0','05 â€” DiagnÃ³sticos')
measure('Percentual de linhas negativas','IF([Linhas faturadas] > 0, DIVIDE([Linhas de lucro negativo],[Linhas faturadas]))',PCT,'05 â€” DiagnÃ³sticos')
measure('ParticipaÃ§Ã£o das condiÃ§Ãµes especiais','IF([Vendas sem impostos] > 0, DIVIDE(CALCULATE([Vendas sem impostos], KEEPFILTERS(FactInvoiceLine[IsSpecial] = TRUE())),[Vendas sem impostos]))',PCT,'05 â€” DiagnÃ³sticos')

# Explicit axis variants avoid guessing the future visual's axis at totals.
axes = {
 'comprador': ('DimBuyer','CustomerID','CustomerName'),
 'conta': ('DimBillingAccount','BillToCustomerID','BillingAccountName'),
 'produto': ('DimProduct','StockItemID','StockItemName'),
 'grupo': ('DimStockGroup','StockGroupID','StockGroupName'),
 'cidade': ('DimGeography','CityID','CityName'),
 'categoria': ('DimBuyer','CustomerCategoryID','CustomerCategoryName'),
 'grupo comprador': ('DimBuyer','BuyingGroupID','BuyingGroupName'),
}
for axis,(table,key,label) in axes.items():
    selected = f'ALLSELECTED({table}[{key}], {table}[{label}])'
    measure('K11 ParticipaÃ§Ã£o â€” '+axis, f'''VAR denominator = CALCULATE([Vendas sem impostos], {selected})
RETURN IF(denominator > 0, DIVIDE([Vendas sem impostos],denominator))''',PCT,'03 â€” ParticipaÃ§Ã£o e concentraÃ§Ã£o',desc='K11. Um eixo de IDs/nomes indicado; filtros externos preservados. NÃ£o usar Top N nativo. Grupos sobrepostos nÃ£o sÃ£o aditivos.')
    if axis in ('comprador','conta','produto'):
        measure('K12 CR5 â€” '+axis, f'''VAR selectedRevenue = CALCULATE([Vendas sem impostos], {selected})
VAR entities = CALCULATETABLE(
    ADDCOLUMNS(VALUES({table}[{key}]), "__Revenue", [Vendas sem impostos]),
    {selected})
VAR topFive = TOPN(5, entities, [__Revenue], DESC, {table}[{key}], ASC)
RETURN IF([_Cobertura] && selectedRevenue > 0, DIVIDE(SUMX(topFive,[__Revenue]),selectedRevenue))''',PCT,'03 â€” ParticipaÃ§Ã£o e concentraÃ§Ã£o',desc='K12. Exatamente cinco IDs (ou menos se seleÃ§Ã£o menor), desempate ID crescente. NÃ£o usar para Stock Groups.')

# Validate complete contiguous civil intervals before removing only the date filter.
for mode in ('AUTO','YOY','MOM','YTD'):
    measure('_Anterior inÃ­cio '+mode, f'''VAR firstDay = MIN(DimDate[CalendarDate])
VAR lastDay = MAX(DimDate[CalendarDate])
VAR contiguous = COUNTROWS(VALUES(DimDate[CalendarDate])) = DATEDIFF(firstDay,lastDay,DAY) + 1
VAR whole = [_Cobertura] && contiguous && DAY(firstDay)=1 && lastDay=EOMONTH(lastDay,0)
VAR singleMonth = EOMONTH(firstDay,0)=lastDay
VAR accumulated = MONTH(firstDay)=1 && YEAR(firstDay)=YEAR(lastDay)
VAR fullYear = accumulated && MONTH(lastDay)=12
VAR mode = IF("{mode}"="AUTO", IF(singleMonth,"YOY",IF(accumulated,"YTD","NONE")),"{mode}")
VAR eligible = whole && SWITCH(mode,"MOM",singleMonth,"YOY",singleMonth || fullYear,"YTD",accumulated,FALSE())
VAR previous = EDATE(firstDay,IF(mode="MOM",-1,-12))
RETURN IF(eligible && previous >= DATE(2013,1,1),previous)''','dd/MM/yyyy','04 â€” ComparaÃ§Ãµes',True)
    measure('_Anterior fim '+mode, f'''VAR firstDay = [_Anterior inÃ­cio {mode}]
VAR lastDay = MAX(DimDate[CalendarDate])
RETURN IF(NOT ISBLANK(firstDay), EOMONTH(lastDay,IF("{mode}"="MOM",-1,-12)))''','dd/MM/yyyy','04 â€” ComparaÃ§Ãµes',True)
    for label,base in [('Vendas','Vendas sem impostos'),('Lucro','Lucro comercial registrado')]:
        measure('_'+label+' anterior '+mode,f'''VAR firstDay = [_Anterior inÃ­cio {mode}]
VAR lastDay = [_Anterior fim {mode}]
RETURN IF(NOT ISBLANK(firstDay), CALCULATE([{base}], REMOVEFILTERS(DimDate),
    DATESBETWEEN(DimDate[CalendarDate],firstDay,lastDay)))''',MONEY,'04 â€” ComparaÃ§Ãµes',True)
    for k, label, expr, fmt in [
      ('K13','VariaÃ§Ã£o de vendas',f'[Vendas sem impostos]-[_Vendas anterior {mode}]',MONEY),
      ('K14','Crescimento de vendas',f'IF([_Vendas anterior {mode}]>0,DIVIDE([Vendas sem impostos]-[_Vendas anterior {mode}],[_Vendas anterior {mode}]))',PCT),
      ('K15','VariaÃ§Ã£o de lucro',f'[Lucro comercial registrado]-[_Lucro anterior {mode}]',MONEY),
      ('K16','VariaÃ§Ã£o de margem',f'IF([Vendas sem impostos]>0 && [_Vendas anterior {mode}]>0,100*([Margem comercial registrada]-DIVIDE([_Lucro anterior {mode}],[_Vendas anterior {mode}])))','0.0000 "p.p.";-0.0000 "p.p.";0.0000 "p.p."')]:
        measure(f'{k} {label} â€” {mode}',f'IF(NOT ISBLANK([_Anterior inÃ­cio {mode}]),{expr})',fmt,'04 â€” ComparaÃ§Ãµes',desc=f'{k}; {mode}. Mesmos filtros nÃ£o temporais. Intervalos parciais/descontÃ­nuos ou sem comparador retornam BLANK.')

tables.append(dict(name='_Medidas',lineageTag=tag('_Medidas'),columns=[dict(name='_Placeholder',dataType='int64',isHidden=True,sourceColumn='_Placeholder',summarizeBy='none')],
    partitions=[dict(name='_Medidas',mode='import',source=dict(type='m',expression='#table(type table [_Placeholder = Int64.Type], {{0}})'))],measures=measures))
model = dict(name='WWI',compatibilityLevel=1600,model=dict(culture='pt-BR',sourceQueryCulture='pt-BR',defaultPowerBIDataSourceVersion='powerBI_V3',
    discourageImplicitMeasures=True, annotations=[dict(name='__PBI_TimeIntelligenceEnabled',value='0')],tables=tables,relationships=relationships))
write(SM/'model.bim',model)
write(SM/'definition.pbism',{'$schema':SCHEMA+'item/semanticModel/definitionProperties/1.0.0/schema.json','version':'4.0','settings':{}})
write(ROOT/'analise_comercial_wwi.pbip',{'$schema':SCHEMA+'pbip/pbipProperties/1.0.0/schema.json','version':'1.0','artifacts':[{'report':{'path':'WWI.Report'}}],'settings':{'enableAutoRecovery':True}})
write(ROOT/'WWI.Report/definition.pbir',{'$schema':SCHEMA+'item/report/definitionProperties/2.0.0/schema.json','version':'4.0','datasetReference':{'byPath':{'path':'../WWI.SemanticModel'}}})
write(ROOT/'WWI.Report/definition/report.json',{'$schema':SCHEMA+'item/report/definition/report/3.0.0/schema.json','themeCollection':{}})
# PBIR report version follows the official Microsoft BCApps PBIR sample.
write(ROOT/'WWI.Report/definition/version.json',{'$schema':SCHEMA+'item/report/definition/versionMetadata/1.0.0/schema.json','version':'2.0.0'})
write(ROOT/'WWI.Report/definition/pages/pages.json',{'$schema':SCHEMA+'item/report/definition/pagesMetadata/1.0.0/schema.json','pageOrder':['00_validacao'],'activePageName':'00_validacao'})
write(ROOT/'WWI.Report/definition/pages/00_validacao/page.json',{'$schema':SCHEMA+'item/report/definition/page/2.0.0/schema.json','name':'00_validacao','displayName':'00_ValidaÃ§Ã£o','displayOption':'FitToPage','height':720,'width':1280})
print(f'Prepared: nine SQL import tables + _Medidas, {len(relationships)} relationships, {len(measures)} measures. Desktop execution not implied.')
