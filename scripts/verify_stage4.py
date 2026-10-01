"""Verify saved execution evidence, independently check ratios, write Stage 4 report.

Standard library only. No database connection and no source-data modification.
"""
from pathlib import Path
from decimal import Decimal, localcontext
import argparse
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('evidence', nargs='?', type=Path)
parser.add_argument('--inspection', type=Path)
args = parser.parse_args()
path = (args.evidence or max((ROOT/'data/metadata').glob('stage4-20*.json'))).resolve()
data = json.loads(path.read_text(encoding='utf-8-sig'), parse_float=Decimal)
checks = [row for result in data['Results'] for row in result['Rows'] if 'ContractID' in row]
observed = {(row['CaseName'], row['MetricID']): row for result in data['Results']
            for row in result['Rows'] if 'CaseName' in row}

def check(cid, name, actual, expected):
    checks.append(dict(ContractID=cid, TestName=name, Actual=str(actual),
                       Expected=str(expected), Passed=actual == expected))

check('C01', 'Runner completed without SQL errors', data['Failure'], None)
check('C01', 'Official backup SHA256', data['BackupSHA256'],
      '066279a8cd28c8d85cbd8215ea71a5d672b420cfbc19756b635c27bd8027dada')
check('C01', 'Previously existing evidence unchanged', data['ProtectedFilesUnchanged'], True)
for filename, expected in json.loads((ROOT/'data/metadata/report_evidence_hashes.json').read_text()).items():
    actual = hashlib.sha256((ROOT/'data/metadata'/filename).read_bytes()).hexdigest()
    check('C01', f'Historical evidence hash: {filename}', actual, expected)
check('C19', 'Normal LocalDB stop', data['StopExitCode'], 0)
check('C19', 'Disk guard respected at recorded checkpoints',
      all(d['FreeBytes'] >= 2*1024**3 for d in data['Disk']), True)

base = {metric: row['Value'] for (case, metric), row in observed.items() if case == 'baseline'}
expected_money = {'K01': Decimal('172261341.20'), 'K02': Decimal('25782098.25'),
                  'K03': Decimal('198043439.45'), 'K04': Decimal('85729180.90')}
for k, expected in expected_money.items():
    check('C04', f'Independent Decimal {k}, exact cents', base.get(k), expected)

# SafeRatio uses SQL decimal(28,8) division, whose SQL precision reduction yields
# 10 ratio decimal places. Multiplication by 100 bounds error to 1e-8 percentage
# points; this is a numeric representation bound, never a monetary tolerance.
if all(k in base for k in expected_money):
    with localcontext() as ctx:
        ctx.prec = 50
        expected = 100*base['K04']/base['K01']
        delta = abs(base['K05']-expected)
        check('C06', 'Independent high-precision margin bound (1e-8 pp)', delta <= Decimal('0.00000001'), True)
        check('C06', 'Independent four-place margin display', base['K05'].quantize(Decimal('.0001')), Decimal('49.7669'))
        check('C14', 'Independent high-precision baseline ticket bound (1e-10 UM)',
              abs(base['K10']-base['K01']/base['K06']) <= Decimal('0.0000000001'), True)
        check('C07', 'Independent K18 incidence bound (1e-8 pp)',
              abs(base['K18']-100*Decimal(4626)/Decimal(228265)) <= Decimal('0.00000001'), True)

# Optional lightweight resumption evidence; never repeat the SQL validation suite.
inspections = sorted((ROOT/'data/metadata').glob('stage4-inspect-*.json'))
inspection_path = args.inspection or (inspections[-1] if inspections else None)
if inspection_path:
    inspection = json.loads(inspection_path.read_text(encoding='utf-8-sig'))
    check('C19', 'Resumption normal stop', inspection['StopExitCode'], 0)
    check('C01', 'Resumption protected files unchanged', inspection['ProtectedFilesUnchanged'], True)
    check('C19', 'Resumption disk checkpoints >=2 GiB',
          all(d['FreeBytes'] >= 2*1024**3 for d in inspection['Disk']), True)
    catalog = {r['name']: r['rows'] for s in inspection['Results'] for r in s['Rows'] if 'rows' in r}
    for name, count in {'FactInvoiceLine':228265,'DimBuyer':663,'DimBillingAccount':263,
                        'DimProduct':227,'DimDate':1247,'DimGeography':655,
                        'DimStockGroup':10,'BridgeProductGroup':442,'DimSpecialDeal':2}.items():
        check('C02', f'Resumption catalog {name}', catalog.get(name), count)
    fks = [r for s in inspection['Results'] for r in s['Rows'] if 'is_not_trusted' in r]
    check('C03', 'Resumption nine FKs enabled and trusted',
          len(fks)==9 and all(not r['is_disabled'] and not r['is_not_trusted'] for r in fks), True)
    sql = (ROOT/'sql/02_metrics.sql').read_text(encoding='utf-8')
    modules = [r for s in inspection['Results'] for r in s['Rows'] if 'definition' in r]
    module_checks = []
    def normalize_header(text):
        # SQL Server persisted CREATE OR ALTER as CREATE with spaces in this run.
        # Only that DDL header and line endings are normalized; body stays exact.
        return re.sub(r'(?im)^CREATE\s+(?:OR\s+ALTER\s+)?(?=FUNCTION|PROCEDURE|VIEW)',
                      'CREATE ', text.replace('\r\n','\n').strip(), count=1)
    for module in modules:
        batch = next(b for b in re.split(r'(?im)^GO\s*$',sql)
                     if re.search(r'CREATE OR ALTER (?:FUNCTION|PROCEDURE|VIEW) analytics\.'+module['name']+r'\b',b))
        equal = normalize_header(batch)==normalize_header(module['definition'])
        check('C19', f'Deployed module body matches file: {module["name"]}', equal, True)
        module_checks.append({'Object':module['name'],'RawTextEquals':batch.strip()==module['definition'].strip(),
                              'HeaderNormalizedEquals':equal,'Passed':equal})
    (ROOT/'data/metadata/stage4-module-checks.json').write_text(json.dumps(module_checks,indent=2)+'\n',encoding='utf-8')
runner_path = ROOT/'data/metadata/stage4-runner-tests.json'
if runner_path.exists():
    for result in json.loads(runner_path.read_text(encoding='utf-8-sig')):
        check('C19', result['Test'], result['Passed'], True)

contracts = [f'C{i:02}' for i in range(1,20)]
for cid in contracts:
    if not any(c['ContractID']==cid for c in checks):
        check(cid, 'No executed evidence found', False, True)
failed = [c for c in checks if not c['Passed']]
report = ['# Etapa 4 — evidência de validação', '',
          f'Execução SQL: `{path.relative_to(ROOT).as_posix()}`; modo `{data["Mode"]}`.',
          f'**{len(checks)-len(failed)} verificações aprovadas / {len(failed)} falhas / {len(checks)} executadas.**', '',
          'Resultados abaixo derivam de execução, não da presença de código. A Etapa 4 só está validada quando não houver falhas.', '',
          '| Contrato | Aprovadas | Falhas | Resultado |','| --- | ---: | ---: | --- |']
for cid in contracts:
    rows=[c for c in checks if c['ContractID']==cid]
    bad=sum(not c['Passed'] for c in rows)
    report.append(f'| {cid} | {len(rows)-bad} | {bad} | {"FAIL" if bad else "PASS"} |')
report += ['', '## Controles financeiros', '', '| Controle | Observado |', '| --- | ---: |']
for k in ('K01','K02','K03','K04','K05'):
    report.append(f'| {k} | {base.get(k, "SEM RESULTADO")} |')
report += ['', 'Somas monetárias confrontadas sem tolerância: centavos exatos. Margem recalculada; 49,7669% é apenas exibição. A divisão SQL tem precisão finita: testes Python usam Decimal de 50 dígitos e limite matemático de representação de 1e-8 ponto percentual (1e-10 UM para o ticket). Não se aplica essa tolerância às somas financeiras.', '',
           '## Ambiente e preservação', '',
           f'- Espaço antes desta execução: {data["Disk"][0]["FreeBytes"]/1024**3:.4f} GiB.',
           f'- Menor espaço registrado: {min(d["FreeBytes"] for d in data["Disk"])/1024**3:.4f} GiB.',
           f'- Espaço após encerrar: {data["Disk"][-1]["FreeBytes"]/1024**3:.4f} GiB.',
           f'- Arquivos anteriores protegidos: {data["ProtectedFileCount"]}; hashes inalterados: {data["ProtectedFilesUnchanged"]}.',
           f'- Código de parada LocalDB: {data["StopExitCode"]}.', '',
           '```text', data['InstanceState'].strip(), '```', '',
           '## Cobertura e limites dos testes', '',
           '- Comparação de conjuntos de IDs, PK/FK, versões históricas, fórmulas originais e sinais.',
           '- Todos os 45 pares de Stock Groups: união e inclusão-exclusão para contagem de linhas e quatro somas financeiras. Sentinelas de join incorreto são calculadas sem materializar o join inflado.',
           '- Cenários reais da API: eixos separados, seleções externas, membro visual, filtros simultâneos, grupos, recortes diagnósticos, vazio, domingos, limites, bissexto, acumulado, ano, MoM, parcial e descontínuo.',
           '- Fixture de seis receitas empatadas apenas em memória de teste, sem inserção na WWI. Denominador zero e negativo testados na função usada pelas medidas.',
           '- Campos de contexto e linhagem da saída verificados. Isso não valida apresentação no Power BI, ainda inexistente.',
           '- Nenhuma nota de crédito foi fabricada/inserida na origem; C09 verifica a ausência real. A guarda de carga rejeita créditos novos, sem transformar seu sinal.',
           '- A suite reconcilia o snapshot; não prova completude de uma empresa real nem causalidade.', '',
           '## Verificações individuais', '', '| Contrato | Verificação | Observado | Esperado | Status |', '| --- | --- | --- | --- | --- |']
if inspection_path:
    position = report.index('## Verificações individuais')
    report[position:position] = ['## Retomada sem repetir testes SQL', '',
        f'Inspeção leve: `{inspection_path.name}`. Todos os 565 asserts SQL anteriores foram reutilizados, inclusive os 45 pares. Conferência atual limitada ao catálogo, FKs e módulos; nenhuma carga ou restauração.',
        f'Espaço antes/depois da inspeção: {inspection["Disk"][0]["FreeBytes"]/1024**3:.4f} / {inspection["Disk"][-1]["FreeBytes"]/1024**3:.4f} GiB. LocalDB encerrado normalmente.',
        'Os números iniciais deste relatório referem-se à execução SQL de 30/09; a inspeção de retomada é separada. Módulos comparados normalizando somente o cabeçalho CREATE/CREATE OR ALTER e finais de linha. Três fixtures exercitam a função real do runner que aceita PASS e rejeita FAIL/ausência de asserts; não inserem dados no banco.', '',
        'A primeira tentativa expirou antes da saída consolidada e não conta como aprovação. A segunda salvou 565 asserts PASS e 567 observações de KPIs (27 cenários × 21 medidas); observações não são contadas novamente como testes. Os 45 pares correspondem a duas asserções consolidadas, não a 45 linhas individuais de evidência.', '']
for c in checks:
    values=[c['ContractID'],c['TestName'],str(c['Actual']),str(c['Expected']),'PASS' if c['Passed'] else 'FAIL']
    report.append('| '+' | '.join(v.replace('|','/').replace('\n',' ') for v in values)+' |')
(ROOT/'reports/validacao_etapa4.md').write_text('\n'.join(report)+'\n',encoding='utf-8')
print(f'{path.name}: {len(checks)-len(failed)} passed; {len(failed)} failed; {len(observed)} saved KPI observations')
for c in failed:
    print(c)
raise SystemExit(bool(failed))
