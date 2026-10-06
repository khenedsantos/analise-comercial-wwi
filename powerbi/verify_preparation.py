"""Read-only structural checks; --generate writes Desktop validation queries only.
Does not connect to SQL/Power BI, execute DAX, or claim semantic PASS.
"""
import argparse
import ast
import hashlib
import json
from decimal import Decimal
from pathlib import Path

P = Path(__file__).resolve().parent
ROOT = P.parent

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'), parse_float=Decimal)

def inspect():
    model = read(P/'WWI.SemanticModel/model.bim')['model']
    tables = {t['name']:t for t in model['tables']}
    expected = {'FactInvoiceLine','DimDate','DimBuyer','DimBillingAccount','DimGeography',
                'DimProduct','DimStockGroup','BridgeProductGroup','DimSpecialDeal','_Medidas'}
    assert set(tables) == expected
    for name,t in tables.items():
        assert len(t['partitions']) == 1 and t['partitions'][0]['mode'] == 'import'
        if name != '_Medidas':
            m = '\n'.join(t['partitions'][0]['source']['expression'])
            assert f'[Schema="analytics",Item="{name}"]' in m
            assert 'CreateNavigationProperties=false' in m
    expected_rel = {('FactInvoiceLine',key,dim,key,'oneDirection') for dim,key in [
        ('DimDate','DateKey'),('DimBuyer','CustomerID'),('DimBillingAccount','BillToCustomerID'),
        ('DimGeography','CityID'),('DimProduct','StockItemID'),('DimSpecialDeal','SpecialDealID')]}
    expected_rel |= {('BridgeProductGroup','StockGroupID','DimStockGroup','StockGroupID','oneDirection'),
                     ('BridgeProductGroup','StockItemID','DimProduct','StockItemID','bothDirections')}
    actual_rel = set()
    for r in model['relationships']:
        assert r['isActive'] and r['fromCardinality']=='many' and r['toCardinality']=='one'
        for end in ('from','to'):
            assert r[end+'Column'] in {c['name'] for c in tables[r[end+'Table']]['columns']}
        actual_rel.add(tuple(r[k] for k in ('fromTable','fromColumn','toTable','toColumn','crossFilteringBehavior')))
    assert actual_rel == expected_rel and len(model['relationships'])==8
    assert tables['DimDate']['dataCategory']=='Time'
    assert next(c for c in tables['DimDate']['columns'] if c['name']=='CalendarDate')['isKey']
    for col in tables['FactInvoiceLine']['columns']:
        if col['name'] in ('SalesExTax','LineProfit','TaxAmount','ExtendedPrice'): assert col['dataType']=='decimal'
        if col['name'] in ('IsSpecial','IsNegative'): assert col['dataType']=='boolean'
    measures = {m['name']:m for m in tables['_Medidas']['measures']}
    assert len(measures)==60
    assert all(name in measures for name in BASE.values())
    for mode in ('AUTO','YOY','MOM','YTD'):
        for k,label in TEMP.items(): assert f'{k} {label} — {mode}' in measures
    assert not any('TODAY(' in '\n'.join(m['expression']).upper() for m in measures.values())
    assert any(a['name']=='__PBI_TimeIntelligenceEnabled' and a['value']=='0' for a in model['annotations'])
    project=read(P/'analise_comercial_wwi.pbip')
    report=P/project['artifacts'][0]['report']['path']
    pointer=read(report/'definition.pbir')
    assert pointer['version']=='4.0'
    assert not (report/'report.json').exists(), 'Do not mix PBIR and PBIR-Legacy.'
    version=read(report/'definition/version.json')
    assert version=={'$schema':'https://developer.microsoft.com/json-schemas/fabric/item/report/definition/versionMetadata/1.0.0/schema.json','version':'2.0.0'}
    assert 'themeCollection' in read(report/'definition/report.json')
    pages=read(report/'definition/pages/pages.json')
    assert pages['pageOrder'] and pages['activePageName'] in pages['pageOrder']
    for page_name in pages['pageOrder']:
        page=read(report/'definition/pages'/page_name/'page.json')
        assert page['name']==page_name
        assert all(key in page for key in ('$schema','displayName','displayOption'))
    assert (report/pointer['datasetReference']['byPath']['path']).resolve()==(P/'WWI.SemanticModel').resolve()
    for f in P.rglob('*.py'): ast.parse(f.read_text(encoding='utf-8'))
    closeout=read(ROOT/'data/metadata/stage4-closeout.json')
    # Locate hash entries independent of the closeout envelope naming.
    def hashes(obj):
        if isinstance(obj,dict):
            for name,val in obj.items():
                if isinstance(val,dict) and 'SHA256' in val and (ROOT/name).is_file():
                    if name.startswith('sql/') or name in ('reports/modelo_etapa4.md','reports/validacao_etapa4.md'):
                        assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==val['SHA256'].lower()
                else: hashes(val)
    hashes(closeout)
    print('Structural checks OK: 10 tables (9 SQL + measures), 8 relationships, 60 measures, fixed decimals, boolean flags, date metadata, pointers and protected hashes.')
    print('Not a TOM/DAX compiler. Desktop opening, refresh and semantic tests remain PENDING.')

BASE={'K01':'Vendas sem impostos','K02':'Impostos','K03':'Faturamento com impostos',
      'K04':'Lucro comercial registrado','K05':'Margem comercial registrada','K06':'Faturas',
      'K07':'Clientes compradores','K08':'Contas de cobrança','K09':'Produtos faturados',
      'K10':'Valor médio do recorte por fatura','K17':'Linhas de lucro negativo',
      'K18':'Percentual de linhas negativas','K19':'Resultado registrado das linhas negativas',
      'K20':'Linhas em condições especiais','K21':'Participação das condições especiais'}
TEMP={'K13':'Variação de vendas','K14':'Crescimento de vendas','K15':'Variação de lucro','K16':'Variação de margem'}
PERCENT={'K05','K11','K12','K14','K18','K21'}

def queries():
    evidence=read(ROOT/'data/metadata/stage4-20260930-120408.json')
    oracle={(r['CaseName'],r['MetricID']):r['Value'] for s in evidence['Results'] for r in s['Rows'] if 'CaseName' in r}
    rows=[]
    def check(label,actual,expected,k=None):
        expected='BLANK()' if expected is None else str(expected)
        # SQL SafeRatio truncation/scale bound from Stage 4; never round money.
        tolerance='0.0000000201' if k=='K16' else '0.0000000101' if k in PERCENT else '0.000000000101' if k=='K10' else '0'
        rows.append(f'''VAR a = {actual}
VAR e = {expected}
RETURN ROW("Teste","{label}","Observado",a,"Esperado",e,
 "Status",IF(IF(ISBLANK(e),ISBLANK(a),NOT ISBLANK(a) && ABS(a-e)<={tolerance}),"PASS","FAIL"))''')
    for k,name in BASE.items():
        check('baseline '+k,('100*' if k in PERCENT else '')+f'[{name}]',oracle['baseline',k],k)
    for name,expected in [('Linhas faturadas',228265),('Negativas não especiais',4114)]:check(name,f'[{name}]',expected)
    for axis,case in [('comprador','baseline'),('conta','billing_axis'),('produto','product_axis')]:
        check('CR5 '+axis,f'100*[K12 CR5 — {axis}]',oracle[case,'K12'],'K12')
    check('K11 total','100*[K11 Participação — comprador]',100,'K11')
    for case,start,end,mode in [('leap_yoy','2016,2,1','2016,2,29','AUTO'),
        ('ytd_2016','2016,1,1','2016,5,31','AUTO'),('annual_2014','2014,1,1','2014,12,31','AUTO'),
        ('mom','2015,5,1','2015,5,31','MOM'),('first_mom','2013,1,1','2013,1,31','MOM'),
        ('first_yoy','2013,1,1','2013,12,31','YOY'),('partial_month','2016,5,2','2016,5,31','AUTO')]:
        for k,label in TEMP.items():
            actual=f'CALCULATE([{k} {label} — {mode}],DATESBETWEEN(DimDate[CalendarDate],DATE({start}),DATE({end})))'
            check(case+' '+k,('100*' if k=='K14' else '')+actual,oracle[case,k],k)
    for k,label in TEMP.items():
        check('discontinuous '+k,f'CALCULATE([{k} {label} — AUTO],TREATAS({{DATE(2016,5,1),DATE(2016,5,31)}},DimDate[CalendarDate]))',None,k)
    for case,filter_arg in [('negative_only','TREATAS({TRUE()},FactInvoiceLine[IsNegative])'),
                            ('special_only','TREATAS({TRUE()},FactInvoiceLine[IsSpecial])'),
                            ('empty_group','TREATAS({5},DimStockGroup[StockGroupID])')]:
        for k in ('K01','K17','K18','K19','K20','K21'):
            expr=f'CALCULATE([{BASE[k]}],{filter_arg})'
            check(case+' '+k,('100*' if k in PERCENT else '')+expr,oracle[case,k],k)
    for case,table,key,axis,ids in [('selected_products','DimProduct','StockItemID','produto','1,2,3,4,5,6'),
        ('selected_buyers','DimBuyer','CustomerID','comprador','1,2,3,4,5,6,7,8'),
        ('group_union','DimStockGroup','StockGroupID','grupo','7,8')]:
        for k in ('K01','K11','K12'):
            if k=='K12' and axis=='grupo':continue
            member=7 if axis=='grupo' else 1
            measure=BASE['K01'] if k=='K01' else f'K11 Participação — {axis}' if k=='K11' else f'K12 CR5 — {axis}'
            # Member filter AFTER evaluation preserves external selection in ALLSELECTED.
            expr=f'MAXX(FILTER(SUMMARIZECOLUMNS({table}[{key}],TREATAS({{{ids}}},{table}[{key}]),"__v",[{measure}]),{table}[{key}]={member}),[__v])'
            check(case+' '+k,('100*' if k in PERCENT else '')+expr,oracle[case,k],k)
    check('group/product intersection','CALCULATE([Vendas sem impostos],TREATAS({7,8},DimStockGroup[StockGroupID]),TREATAS({1,2,3},DimProduct[StockItemID]))',oracle['group_product_intersection','K01'],'K01')
    # Set comparison: relationship propagation vs explicit deduplicated product IDs.
    for groups in ('7,8','1,2,3,4,5,6,7,8,9,10','5'):
        expr=f'''VAR products = CALCULATETABLE(VALUES(BridgeProductGroup[StockItemID]),TREATAS({{{groups}}},BridgeProductGroup[StockGroupID]))
VAR propagated = CALCULATETABLE(VALUES(FactInvoiceLine[InvoiceLineID]),TREATAS({{{groups}}},DimStockGroup[StockGroupID]))
VAR explicitUnion = CALCULATETABLE(VALUES(FactInvoiceLine[InvoiceLineID]),REMOVEFILTERS(DimStockGroup),TREATAS(products,FactInvoiceLine[StockItemID]))
RETURN COALESCE(COUNTROWS(EXCEPT(propagated,explicitUnion)),0)+COALESCE(COUNTROWS(EXCEPT(explicitUnion,propagated)),0)'''
        check('bridge IDs '+groups, '('+expr+')',0)
    check('no duplicated grain','COUNTROWS(FactInvoiceLine)-DISTINCTCOUNT(FactInvoiceLine[InvoiceLineID])',0)
    check('calendar days','COUNTROWS(DimDate)',1247)
    text='// Generated from frozen SQL evidence. Execute in Desktop DAX query view AFTER refresh.\n// No SQL execution, no visual filters. Expected money exact; ratios use Stage 4 precision bounds.\nEVALUATE\nUNION(\n'+',\n'.join('('+r+')' for r in rows)+'\n)\nORDER BY [Teste]\n'
    return text,len(rows)

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--generate',action='store_true')
    args=parser.parse_args()
    inspect()
    text,count=queries()
    output=P/'validacao_desktop.dax'
    if args.generate:output.write_text(text,encoding='utf-8')
    else:assert output.read_text(encoding='utf-8')==text,'Validation query differs from frozen oracle.'
    print(f'{count} Desktop assertions PREPARED, not executed. No semantic PASS claimed.')
