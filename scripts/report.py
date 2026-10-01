"""Render stage-2 evidence from saved SQL outputs. No additional dependencies."""
import calendar
import hashlib
import json
from collections import Counter, defaultdict
from datetime import date, timedelta
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
META = ROOT / 'data/metadata'
REPORTS = ROOT / 'reports'

def load(name):
    return json.loads((META / name).read_text(encoding='utf-8-sig'), parse_float=Decimal)

def sections(doc):
    out = defaultdict(list)
    for result in doc['results']:
        for row in result['rows']:
            if 'section' in row:
                out[row['section']].append(row)
    return out

def fmt(x, places=0):
    if x is None: return '—'
    return f'{x:,.{places}f}'.replace(',', '_').replace('.', ',').replace('_', '.')

def table(headers, rows):
    def cell(x): return str(x).replace('|', '\\|').replace('\n', ' ')
    return '\n'.join(['| '+' | '.join(headers)+' |', '| '+' | '.join(['---']*len(headers))+' |'] + ['| '+' | '.join(cell(x) for x in row)+' |' for row in rows])

def main():
    a = sections(load('audit.json'))
    f = sections(load('followup.json'))
    e = sections(load('exceptions.json'))
    p = sections(load('pricing_semantics.json'))
    inv, integrity, manifest = load('inventory.json'), load('integrity.json'), load('source_manifest.json')
    final_env = load('final_environment.json')
    v, finance, rec = a['volumes'][0], a['signs_financials'][0], a['reconciliation'][0]
    monthly = a['monthly']
    # Independent reconciliation of the exported evidence, with exact decimal arithmetic.
    assert sum(r['sales_ex_tax'] for r in monthly) == finance['amount_ex_tax']
    assert sum(r['profit'] for r in monthly) == finance['line_profit']
    assert finance['amount_ex_tax'] + finance['tax'] == finance['extended_price']
    assert sum(r['documents'] for r in monthly) == v['invoices']
    assert sum(r['lines'] for r in monthly) == v['invoice_lines']
    assert all(r['orphans']==0 for r in a['fk_actual'])
    assert all(r['total_rows']==r['distinct_pk'] and r['null_pk']==0 for r in f['pk_actual'])
    assert any('0 allocation errors and 0 consistency errors' in x for x in integrity['messages'])
    assert all(rec[k]==0 for k in ['net_vs_qty_price_mismatches','tax_mismatches','extended_mismatches'])
    assert p['low_price_temporal_coverage'][0]['joined_lines']==v['invoice_lines']
    assert sum(r['lines'] for r in p['low_price_vs_deal'])==p['low_price_temporal_coverage'][0]['below_historical_list']
    dates={date.fromisoformat(r['InvoiceDate'][:10]) for r in a['daily']}
    start,end=min(dates),max(dates)
    absent=[start+timedelta(days=i) for i in range((end-start).days+1) if start+timedelta(days=i) not in dates]
    assert len(monthly)==41 and all(x.weekday()==6 for x in absent)
    years=defaultdict(lambda: {'months':0,'documents':0,'lines':0,'sales':Decimal(0),'profit':Decimal(0)})
    for r in monthly:
        q=years[r['year']]; q['months']+=1; q['documents']+=r['documents']; q['lines']+=r['lines']; q['sales']+=r['sales_ex_tax']; q['profit']+=r['profit']
    yearly_table=table(['Ano','Meses','Faturas','Linhas','Vendas sem impostos'], [[y,q['months'],fmt(q['documents']),fmt(q['lines']),fmt(q['sales'],2)] for y,q in years.items()])
    pk_table=table(['Tabela','Registros','PK distinta','PK nula'],[[r['table_name'],fmt(r['total_rows']),fmt(r['distinct_pk']),r['null_pk']] for r in f['pk_actual']])
    nulls=[r for r in a['nulls'] if r['nulls']>0]
    null_table=table(['Tabela','Coluna','Nulos','Total'],[[r['table_name'],r['column_name'],fmt(r['nulls']),fmt(r['total_rows'])] for r in nulls])
    monthly_table=table(['Mês','Primeira fatura','Última fatura','Dias com faturas','Faturas','Linhas','Vendas sem impostos','LineProfit'],
       [[f"{r['year']}-{r['month']:02}",r['first_date'][:10],r['last_date'][:10],r['days_with_documents'],fmt(r['documents']),fmt(r['lines']),fmt(r['sales_ex_tax'],2),fmt(r['profit'],2)] for r in monthly])
    cat_table=table(['Categoria do cliente','Clientes'],[[r['CustomerCategoryName'],r['registered_customers']] for r in a['categories_customers']])
    group_table=table(['Stock Group','Produtos associados'],[[r['StockGroupName'],r['products']] for r in a['stock_groups']])
    neg=e['negative_profit'][0]
    bridge=a['bridge_join_effect'][0]
    peaks=[]
    for y in [2013,2014,2015]:
        best=max((r for r in monthly if r['year']==y),key=lambda r:r['sales_ex_tax'])
        peaks.append(f"{y}: {best['month']:02}/{y}")
    functions=META/'embedded_modules'
    functions.mkdir(exist_ok=True)
    for result in inv['results']:
        for row in result['rows']:
            if row.get('section')=='modules':
                (functions/f"{row['schema_name']}.{row['object_name']}.sql").write_text(row['definition'].replace('\r\n','\n'),encoding='utf-8')
    for row in p['source_functions']:
        (functions/f"{row['schema_name']}.{row['object_name']}.sql").write_text(row['definition'].replace('\r\n','\n'),encoding='utf-8')
    text=f'''# Etapa 2 — Aquisição e diagnóstico da Wide World Importers OLTP

**Projeto:** Performance Comercial e Rentabilidade: análise de faturamento, margem e concentração de carteira.

**Estado:** diagnóstico concluído; não há modelo dimensional definitivo, dashboard, publicação ou recomendação comercial definitiva.

**Convenção de evidência:** **[FATO]** resultado observado neste arquivo; **[MICROSOFT]** documentação/código oficial, inclusive módulos extraídos do backup; **[PROPOSTA]** decisão analítica a revisar na próxima etapa. Valores monetários são unidades monetárias da base, sem conversão para reais. Não há código de moeda nas linhas auditadas; não acrescentamos uma moeda não registrada como se fosse um campo da fonte.

## 1. Fonte exata e aquisição

**[FATO]** Fonte exclusiva: repositório oficial `microsoft/sql-server-samples`. O backup existente foi reutilizado e seu hash revalidado; não houve novo download do dataset na retomada.

| Atributo | Registro |
| --- | --- |
| Release | `{manifest['release']}` |
| Página oficial | {manifest['release_url']} |
| Download exato | {manifest['download_url']} |
| Arquivo | `{manifest['filename']}` |
| Formato | Backup completo comprimido SQL Server `.bak`, OLTP Standard |
| Tamanho | {manifest['size_bytes']} bytes ({manifest['size_bytes']/Decimal(1048576):.2f} MiB) |
| Publicação da release | {manifest['release_published_at']} |
| Asset oficial | ID {manifest['asset_id']}; criado em {manifest['asset_created_at']}; atualizado em {manifest['asset_updated_at']} |
| Obtenção local | {manifest['obtained_at_utc']} — timestamp preservado do término do download; 29/09/2026 às 08:52:09 em São Paulo |
| Cabeçalho do backup | Início em 07/10/2022 15:04:13; término 15:04:14; SQL Server 13.0.1601; sem fuso atribuível à sessão de origem |
| Licença | MIT, com avisos Microsoft preservados em `data/metadata/microsoft-license.txt` |
| Commit da documentação adicional | `{manifest['documentation_commit']}` |

SHA-256:

```text
{manifest['sha256']}
```

**[MICROSOFT]** [Licença oficial](https://github.com/microsoft/sql-server-samples/blob/{manifest['documentation_commit']}/license.txt) e [termos/contexto WWI](https://learn.microsoft.com/en-us/sql/samples/wide-world-importers-what-is). A documentação informa dados geográficos originados de data.gov e Natural Earth; esses avisos não devem ser omitidos em eventual redistribuição. A licença do nosso código não substitui os avisos da fonte. Nenhuma redistribuição foi feita.

**[FATO]** `release.json` registra a resposta da API GitHub; `source_manifest.json` registra URLs, datas e hashes. A data de 2016 da release não é a data deste arquivo nem sua cobertura transacional. Não foi executado o gerador para estender ou atualizar datas.

## 2. Ambiente e restauração

**[FATO]** Windows 11 x64, aproximadamente 8 GiB de RAM; Python 3.14.6 já instalado. LocalDB 2025 instalado com assinatura Microsoft verificada, versão `17.0.1000.7`. Instância exclusiva `(localdb)\\WWI_Portfolio`; banco `WWI_Portfolio_Diagnostic`. SQL Server Express real, com execução local sob demanda, sem servidor remoto.

O backup foi verificado com `RESTORE HEADERONLY`, `FILELISTONLY` e `VERIFYONLY`. Os caminhos `D:` do computador de origem não existem aqui; os avisos iniciais sobre esses caminhos foram resolvidos com `WITH MOVE` para `data/sqlserver`. Restauração sem `REPLACE`, com proteção contra sobrescrever banco existente.

Os arquivos restaurados alocam **3.172 MiB**: primário 1.024 MiB, dados 2.048 MiB, log 100 MiB. A restauração foi condicionada a reserva adicional de 2 GiB. O banco estava ONLINE e consultável. A inspeção posterior apontou 11,5 MiB usados no primário e 551,8125 MiB no arquivo de dados; o restante é espaço interno alocado, não outro download.

**[FATO]** `DBCC CHECKDB ... WITH TABLOCK, ALL_ERRORMSGS, MAXDOP=1` concluiu com **zero erros de alocação e zero erros de consistência**. `VERIFYONLY` não substituiu essa checagem: o backup informa `HasBackupChecksums=false`.

A execução inicial do CHECKDB e algumas agregações aguardaram memória (`RESOURCE_SEMAPHORE`). Foram canceladas somente consultas deste projeto e repetidas com execução serial; a instância foi limitada a `MAXDOP=1` e `max server memory=512 MiB`. Esse teto refere-se à memória gerenciada pela configuração SQL, não a um limite absoluto de todo o processo. Agregações específicas usam limite de concessão de memória. Os registros de negócio não foram alterados.

**[PROPOSTA]** LocalDB + Python continua adequado para o recorte. Nesta etapa, Python padrão registra proveniência, valida as saídas e gera este relatório; Windows PowerShell/.NET `SqlClient`, já disponível, executa SQL sem instalar driver Python ou SSMS. pandas permanece possível para a próxima etapa, sem instalação antecipada. Power BI em Import continua sendo proposta: não foi instalado, aberto ou validado neste computador. A memória limitada recomenda carregar futuramente apenas o recorte comercial.

Os dois instaladores baixados pelo projeto foram removidos após a instalação confirmada. Backup, banco e evidências foram preservados; nenhum arquivo pessoal foi removido. Não houve cloud, Docker, SSIS, Fabric, Azure, GitHub ou commits.

**[FATO — encerramento]** Instância parada de forma normal para liberar memória, sem remover o banco. Espaço livre no encerramento: {fmt(Decimal(final_env['free_disk_bytes'])/Decimal(1073741824),2)} GiB, medido em {final_env['captured_at']}. SHA-256 do backup novamente confirmado. O banco foi validado ONLINE antes da parada; a conexão/rotina de início reativa a instância. Detalhes em `environment.json` e `final_environment.json`.

## 3. Inventário e granularidade

**[FATO]** O catálogo contém 48 tabelas, incluindo históricos e dados de sensores. O diagnóstico comercial utiliza o subconjunto abaixo. Contagens das chaves são exatas, não estimativas do catálogo.

{pk_table}

`Invoices`: uma linha por documento; `InvoiceLines`: uma linha por item faturado. Campos centrais: `InvoiceID`, `InvoiceLineID`, `InvoiceDate`, `OrderID`, `CustomerID`, `BillToCustomerID`, `StockItemID`, `PackageTypeID`, `Quantity`, `UnitPrice`, `TaxRate`, `TaxAmount`, `ExtendedPrice`, `LineProfit`, `IsCreditNote`.

`Customers`: categoria, grupo comprador e localização; `StockItems`: nome e atributos; `StockItemHoldings.LastCostPrice`: último custo cadastrado, sem série histórica própria nessa tabela; `StockItemStockGroups`: associação multivalorada. `CustomerTransactions` foi usado apenas para conciliação do faturamento, sem somar pagamentos às vendas.

Há 51 versões em `Customers_Archive`, referentes a 46 clientes, e 444 versões em `StockItems_Archive`. O histórico não deve ser unido sem condição de vigência. Inventário completo, tipos, nulabilidade e descrições estão em `inventory.json`; o dicionário do recorte está em [dicionario_diagnostico.md](dicionario_diagnostico.md).

## 4. Período disponível e comparabilidade

**[FATO]** Faturas entre **01/01/2013 e 31/05/2016**, abrangendo 41 meses consecutivos. Clientes com faturamento: 663/663; produtos vendidos: 227/227. Pedidos e transações de clientes têm os mesmos limites de datas.

{yearly_table}

Existem {len(dates)} dias com faturas e {len(absent)} dias sem faturas no intervalo. **Todos os dias ausentes são domingos; nenhum dia de segunda a sábado falta.** Meses cuja última fatura é dia 29 ou 30 terminam em domingo quando isso ocorre. Maio/2016 começa a faturar no dia 2 porque o dia 1 é domingo; termina no dia 31. Não foi encontrado mês cortado no meio na janela observada. Isso é consistência de cobertura da amostra, não garantia externa de completude de uma operação real.

2013, 2014 e 2015 possuem 12 meses; 2016 possui apenas janeiro–maio. Não comparar o total de 2016 com anos inteiros. Fevereiro/2016 tem 29 dias; diferenças de dias e de sábados precisam ser consideradas em comparações mensais.

**Sazonalidade aparente [FATO]:** há padrão semanal claro (ausência de domingos) e os máximos mensais de vendas sem impostos foram {'; '.join(peaks)}. Julho lidera em dois anos, mas três ciclos, composição e diferenças de dias não estabelecem sazonalidade anual robusta. Não há base para previsão sazonal nesta etapa.

**[MICROSOFT]** O gerador incorporado contém multiplicadores anuais de pedidos (1,00 em 2013; 1,12 em 2014; 1,21 em 2015; 1,23 em 2016), aleatoriedade e parâmetros de fim de semana. A tendência é influenciada pelo processo de simulação. A documentação descreve ano fiscal iniciado em novembro; ele não foi confundido com ano civil neste relatório.

**[PROPOSTA]** Preservar a janela completa 01/01/2013–31/05/2016. Usar **janeiro–maio/2016 contra janeiro–maio/2015** como recorte executivo inicial; oferecer **2013–2015** para comparação de anos civis completos. Comparações mensais YoY só a partir de janeiro/2014. Não tratar meses posteriores a maio/2016 como vendas zero. A evidência mensal integral está em [perfil_mensal.md](perfil_mensal.md).

## 5. Integridade, qualidade e sinais

**[FATO]** As 17 tabelas centrais têm PK sem nulos nem duplicidades. Foram conferidas por anti-join as **98 FKs declaradas** da base: zero órfãos. As 98 estavam habilitadas e confiáveis. CHECKDB passou. A consulta executou como `dbo`/sysadmin; a política RLS permite `db_owner`, evitando recorte invisível por território nessa auditoria.

Nas 228.265 linhas: zero quantidades nulas/zero/negativas; zero preços nulos/zero/negativos; zero impostos e totais faturados nulos/zero/negativos. Quantidade varia de 1 a 360 e preço de 0,66 a 1.899,00. `LineProfit` não tem nulos nem zeros; possui **4.626 negativos**, sem serem notas de crédito. Lucro por linha varia de −645,00 a 9.200,00.

Não foram encontradas duplicidades no conjunto de atributos comerciais da linha (desconsiderando seu ID), nem repetição de produto dentro da mesma fatura. Nomes de produtos e clientes são únicos nesta amostra, mas a identificação deve continuar usando IDs. Compras recorrentes do mesmo produto em outras faturas são eventos legítimos, não duplicidades.

Taxas de imposto: 15% em 227.229 linhas e 10% em 1.036. São valores da simulação, não uma validação de legislação tributária. Embalagens vendidas: Each, Packet, Bag e Pair; somar quantidades heterogêneas não cria uma medida física homogênea.

**Ausências e classificações [FATO]:**

- Nenhum cliente sem categoria ou com categoria órfã; 261 sem Buying Group. Ausência de associação a grupo comprador não é ausência de segmento.
- Nenhum produto sem Stock Group; nenhum par produto/grupo duplicado.
- 209/227 produtos sem marca (92,07%); 64 sem tamanho; 99 sem cor. Não recomendar análise por marca como dimensão principal.
- 84 faturas sem confirmação de entrega. Não excluí-las do faturamento; entrega é outro evento.
- `CreditNoteReason` vazio em todas as faturas é compatível com ausência de notas de crédito.
- 11.048/37.940 cidades de referência sem população registrada. Não usar população como denominador comercial sem novo diagnóstico.

Categorias cadastradas versus uso efetivo:

{cat_table}

{group_table}

Categorias sem clientes e `Airline Novelties` sem produtos não são vendas ausentes a imputar. A lista contém opções não utilizadas. Há 655 cidades e 49 unidades de `StateProvinces` representadas pelos clientes, todas em United States; nenhuma falta na cadeia cidade → estado/província → país ou na coordenada de entrega dos clientes.

## 6. Reconciliações financeiras

**[MICROSOFT]** Tanto `Website.InvoiceCustomerOrders` quanto a definição de `DataLoadSimulation.InvoicePickedOrders` incorporada no backup usam:

```text
Valor sem impostos = ROUND(Quantity × UnitPrice, 2)
TaxAmount = ROUND(Quantity × UnitPrice × TaxRate / 100, 2)
ExtendedPrice = valor sem impostos + TaxAmount
LineProfit = ROUND(Quantity × (UnitPrice − LastCostPrice), 2)
```

Na geração, `LastCostPrice` vem de `Warehouse.StockItemHoldings` no momento do faturamento. A descrição oficial da coluna vincula o resultado ao custo vigente. [Código oficial adicional fixado](https://github.com/microsoft/sql-server-samples/blob/{manifest['documentation_commit']}/samples/databases/wide-world-importers/wwi-ssdt/wwi-ssdt/Website/Stored%20Procedures/InvoiceCustomerOrders.sql). Os módulos efetivamente contidos no backup foram preservados em `data/metadata/embedded_modules`.

**[FATO]** Auditoria exata com tipos decimais, sem tolerância arbitrária:

| Reconciliação | Registros verificados | Divergências |
| --- | --- | --- |
| ExtendedPrice − TaxAmount versus ROUND(Quantity × UnitPrice, 2) | 228.265 linhas | 0; maior diferença 0,00 |
| TaxAmount versus fórmula acima | 228.265 linhas | 0; maior diferença 0,00 |
| ExtendedPrice versus preço × quantidade + imposto arredondado | 228.265 linhas | 0 |
| LineProfit versus Quantity × (UnitPrice − LastCostPrice atual), arredondado | 228.265 linhas | 0 |
| Valores sem imposto, impostos e totais por fatura versus CustomerTransactions | 70.510 faturas | 0 nas três medidas |
| Soma dos meses versus total exportado | 41 meses | 0 |

Cada fatura tem exatamente uma transação com `InvoiceID` para essa conciliação. Pagamentos não foram incluídos no somatório de faturamento.

Totais de controle, **não apresentação de impacto ou recomendação**:

| Controle | Valor |
| --- | --- |
| Vendas sem impostos | {fmt(finance['amount_ex_tax'],2)} |
| Impostos | {fmt(finance['tax'],2)} |
| Total faturado com impostos | {fmt(finance['extended_price'],2)} |
| Soma de LineProfit | {fmt(finance['line_profit'],2)} |
| Margem registrada (razão entre somas) | {fmt(finance['line_profit']/finance['amount_ex_tax']*100,4)}% |

O custo unitário implícito `(ExtendedPrice − TaxAmount − LineProfit) / Quantity` é constante por produto nesta amostra; nenhum dos 227 produtos tem mais de um custo implícito observado. Todos coincidem com o último custo atual. **Isso valida o cálculo neste arquivo, mas não prova reconstrução histórica de custos em geral.** Não se deve substituir o lucro registrado por custo atual em futuras versões sem revalidar. O custo implícito não é observação independente: é derivado do próprio lucro.

## 7. Valores inesperados e semântica de descontos

**[FATO]** As 4.626 linhas de lucro negativo abrangem {fmt(neg['invoices'])} faturas e {neg['products']} produtos, com soma de LineProfit {fmt(neg['negative_profit_total'],2)}. Esse valor não é receita perdida, prejuízo líquido nem ganho recuperável. São 18 produtos: quatro com preço 18 e custo 19, e 14 produtos com preços especiais. Exemplo rastreável: linha 43, fatura 21, produto 144, quantidade 24, preço 18, imposto 64,80, total 496,80 e LineProfit −24; a fórmula usa custo 19 e fecha exatamente.

**[MICROSOFT — implementação da amostra]** `Website.CalculateCustomerPrice` calcula a alternativa percentual como `ROUND(preço_base × DiscountPercentage / 100, 2)`. Não calcula `preço_base × (1 − percentual/100)`. As descrições dos acordos mencionam 10% e 15%, mas a implementação cobra 10% e 15% do preço-base.

**[FATO]** Reconciliação usando data do pedido, grupo comprador, associação ao grupo de produtos e preço cadastral com vigência:

| Acordo | Percentual cadastrado | Linhas elegíveis | Preço igual a percentual × base | Preço igual a base menos percentual | Lucro negativo |
| --- | --- | --- | --- | --- | --- |
| 1 | 10% | 301 | 301 | 0 | 301 |
| 2 | 15% | 211 | 211 | 0 | 211 |

Todas as **512** linhas abaixo do preço cadastral histórico estão nesses grupos verificados. A junção temporal de produto preservou as 228.265 linhas, sem vigência ausente. São os únicos 14 produtos com mais de um preço realizado (três preços cada); 213 têm preço único. Os 663 clientes têm `StandardDiscountPercentage=0`.

**[PROPOSTA]** Registrar a divergência entre rótulo do desconto e implementação como limitação de qualidade semântica da amostra. Preservar as linhas e preços originais, com identificação analítica transparente. Não corrigir valores, não recalcular receita hipotética e não narrar um erro de precificação de uma empresa real. Uma análise futura de preços deve separar esse mecanismo da amostra. Não chamar o campo de desconto efetivo de 10%/15%.

## 8. Definições financeiras defensáveis

**[PROPOSTA apoiada nas regras e reconciliações]** O dicionário inicial é:

| Termo | Definição e população |
| --- | --- |
| Vendas faturadas sem impostos | Soma de `ExtendedPrice − TaxAmount`, em documentos `IsCreditNote=0`; será a medida principal de vendas, com rótulo explícito |
| Total faturado com impostos | Soma de `ExtendedPrice`, nas mesmas faturas; controle distinto de vendas sem impostos |
| Impostos faturados | Soma de `TaxAmount`, nas mesmas faturas |
| Créditos registrados | Valores de documentos `IsCreditNote=1`; não existem nesta versão, portanto quantidade e total observados são zero |
| Vendas líquidas de créditos, sem impostos | Vendas sem impostos mais ajustes de crédito com sinal validado; nesta versão coincide com vendas, mas o comportamento de créditos não foi testado empiricamente |
| Lucro comercial registrado | Soma de `LineProfit`, preservando valores negativos; resultado sobre o custo de produto utilizado pela amostra |
| Margem comercial registrada | Soma de `LineProfit` dividida pela soma de vendas sem impostos para a mesma população; não média das margens das linhas |

Não usar lucro líquido, EBITDA ou margem de contribuição: não há conciliação de despesas operacionais, financeiras, impostos sobre resultado nem todos os custos variáveis. Faturamento não equivale a caixa. O título pode manter rentabilidade, desde que explicado como **rentabilidade comercial registrada sobre o custo de produto da amostra**.

## 9. Notas de crédito: limite da evidência

**[FATO]** Zero faturas `IsCreditNote=1`, zero quantidades negativas e zero valores faturados negativos. Não há amostra empírica para validar sinais, referência à fatura original ou reversão de lucro em créditos. Lucro negativo em venda positiva não é nota de crédito.

**[MICROSOFT]** A documentação descreve notas de crédito como faturas negativas. Isso descreve o sistema, não demonstra sua ocorrência neste arquivo.

**[PROPOSTA]** Manter o indicador original e uma validação para reauditar futuras notas. Não aplicar `ABS`, não inverter sinais preventivamente e não excluir lucro negativo. Ao receber outra versão com créditos, verificar sinais de quantidade, imposto, total e lucro, duplicidades e vínculo com a operação original antes de incorporá-la. Retirar a análise de créditos/devoluções do escopo principal atual; zero não permite diagnosticar uma política de devoluções.

## 10. Cardinalidades e riscos de joins

**[FATO]**

- Fatura → linhas: 1 a 5 linhas; nenhuma fatura sem linha; média 3,237342. A junção correta preserva 228.265 linhas.
- Pedido → fatura: máximo de uma fatura por `OrderID` observado; todos os documentos faturados possuem pedido. Há 73.595 pedidos, dos quais 3.085 não têm fatura associada. A existência dessa diferença não foi classificada como perda de venda ou atraso.
- Cliente comprador: 663; cliente de cobrança (`BillToCustomerID`): 263. Em 400 cadastros o cliente comprador difere do destinatário da cobrança. Não são duplicidades de cliente.
- Produto → Stock Groups: 94 produtos em um grupo, 51 em dois e 82 em três; 442 associações, sem pares repetidos.
- Juntar linhas diretamente à ponte aumenta o conjunto para **{fmt(bridge['lines_after_join'])} linhas** e infla a soma de vendas de **{fmt(bridge['original_amount'],2)} para {fmt(bridge['amount_after_join'],2)}**, aumento de {fmt((bridge['amount_after_join']/bridge['original_amount']-1)*100,2)}%. Isso é duplicação analítica, não venda adicional.
- Juntar itens do pedido e itens da fatura apenas por `OrderID` gera **847.091 linhas**, embora haja 228.265 linhas faturadas. Mesmo o relacionamento 1:1 observado entre cabeçalhos não torna as tabelas de itens 1:1 por pedido.
- Versões temporais de cliente unidas com vigência preservam 70.510 faturas, sem falta de versão. Cidade e categoria históricas coincidem com o cadastro atual em todas essas faturas; as versões arquivadas também não mudam o grupo comprador. Isso sustenta uma simplificação específica desta versão, não uma regra universal de modelagem.

**[PROPOSTA]** Definir explicitamente comprador versus cobrança nas métricas de concentração. Tratar Stock Groups como classificações sobrepostas; não somar subtotais como categorias exclusivas nem ratear receita sem regra aprovada. Dimensões e ponte serão decididas na próxima etapa, não foram implementadas aqui.

## 11. Reavaliação das perguntas originais

| Pergunta | Classificação | Delimitação após auditoria |
| --- | --- | --- |
| Receita e lucro crescem na mesma direção? | Sustentada com ressalvas | Mesmos períodos; crescimento programado e natureza simulada precisam ser visíveis |
| Quais produtos contribuem para a variação do lucro? | Sustentada | Decomposição contábil por produto e períodos comparáveis; sem causalidade |
| Quais clientes combinam receita elevada e margem baixa? | Sustentada com ressalvas | Definir comprador/cobrança e critério de comparação; não inventar meta nem margem mínima |
| Quanto do faturamento se concentra em poucos clientes/produtos? | Sustentada | IDs e agregação sem duplicar grupos; duas visões de cliente são possíveis |
| Diferenças geográficas persistem com produtos/segmentos semelhantes? | Sustentada com ressalvas | Geografia completa; suporte de cada comparação e tamanhos dos grupos devem ser examinados na análise |
| Qual o peso das notas de crédito? | Não sustentada como investigação comercial | Ausência de documentos: pode-se informar zero, mas não estudar padrão ou impacto |
| Há diferenças persistentes de preço no mesmo produto/embalagem? | Sustentada com ressalvas | Variação em apenas 14 produtos, ligada às condições e à implementação percentual da amostra |
| A margem agregada acompanha mudanças no mix? | Sustentada | Custos implícitos constantes ajudam a decomposição; mudanças de preços especiais devem ser separadas |

**Perguntas adicionais propostas, ainda não respondidas como conclusão comercial:** como linhas de resultado negativo compõem o resultado agregado? Como muda a concentração ao usar comprador versus conta de cobrança? Quanto da variação observada da margem corresponde ao mix e quanto aos preços especiais registrados? Quais limitações surgem ao apresentar Stock Groups como categorias exclusivas?

Descartar, por ora: efeito causal de desconto, otimização de preço, recuperação financeira hipotética, análise de inflação de custos, atingimento de metas, retenção/churn definitivo e rentabilidade por marca. Não há variação histórica de custo implícito nesta amostra para investigar inflação de custos.

## 12. Limitações descobertas e próxima etapa

**[FATO/MICROSOFT]** Base sintética; tendência influenciada por gerador; nenhuma nota de crédito; custo implícito constante por produto; mecanismo percentual incompatível com a interpretação usual de desconto; classificações sobrepostas; marca majoritariamente ausente; 2016 parcial; quantidades com embalagens distintas; resultado comercial sem despesas completas. O snapshot possui corte de eventos em maio/2016, mesmo sendo um backup criado em 2022.

**[PROPOSTA]** Manter WWI: os dados sustentam faturamento, margem registrada e concentração, com rastreabilidade suficiente. A próxima etapa deve fechar o contrato analítico: população de faturas, definições de receita/lucro/margem, tratamento das 512 linhas de preços especiais sem alteração da fonte, comprador versus cobrança, regra de apresentação dos grupos e comparações de períodos. Só depois desenhar o modelo e executar análises comerciais.

Critérios de aceitação propostos para a próxima etapa: preservar totais de controle; impedir duplicação por joins; manter todos os sinais originais; documentar denominadores; separar ausência de dado de zero; apresentar ressalvas do gerador e das condições de preço. Nenhuma meta, limiar comercial, stakeholder ou impacto foi inventado.

## 13. Evidências e reprodução

- `source_manifest.json`, `release.json`, `backup_inspection.json`, `restore.json`: origem e restauração.
- `inventory.json`: tabelas, colunas, chaves, descrições e módulos oficiais.
- `audit.json`: 28 conjuntos de resultados; inclui 98 verificações de FKs e perfil de nulos.
- `followup.json`: 14 conjuntos; chaves, histórico, preços e acesso/RLS.
- `exceptions.json`: 5 conjuntos; valores negativos e vigência de clientes.
- `pricing_semantics.json`: 4 conjuntos; código de precificação e reconciliação das condições.
- `integrity.json`: mensagens completas de CHECKDB e tamanho dos arquivos.
- `instance_configuration.json`: limites da instância.

As consultas foram aplicadas à base original restaurada, sem alterações de dados. Tabelas temporárias de auditoria não são um modelo dimensional. `scripts/report.py` também confere a soma dos meses contra totais, a identidade faturamento = vendas + impostos e a consistência dos outputs antes de produzir este documento.

Para comandos de reprodução, consultar [README](../README.md). Backup e arquivos do banco estão excluídos pelo `.gitignore`. Não foi criado ou publicado repositório Git.

## Anexo — Nulos efetivamente encontrados no recorte perfilado

Todas as demais colunas das dez tabelas perfiladas em `audit.sql` tiveram zero nulos. Ausência em atributos opcionais não foi convertida em erro de integridade.

{null_table}
'''
    REPORTS.mkdir(exist_ok=True)
    (REPORTS/'diagnostico_etapa2.md').write_text(text,encoding='utf-8')
    (REPORTS/'perfil_mensal.md').write_text('# Cobertura mensal observada\n\nValores de controle em unidades monetárias da fonte. Zero notas de crédito; todos os dias ausentes são domingos. Meses inteiros dentro da cobertura observada não significam garantia externa de completude.\n\n'+monthly_table+'\n',encoding='utf-8')
    relevant={r['table_name'] for r in f['pk_actual']}
    cols=[r for result in inv['results'] for r in result['rows'] if r.get('section')=='columns' and r['schema_name']+'.'+r['table_name'] in relevant]
    dictionary=table(['Tabela','Coluna','Tipo SQL','Aceita NULL','Descrição da fonte'],[[r['schema_name']+'.'+r['table_name'],r['column_name'],r['data_type']+(f"({r['precision']},{r['scale']})" if r['data_type'] in ('decimal','numeric') else ''),'sim' if r['is_nullable'] else 'não',r['description'] or ''] for r in cols])
    (REPORTS/'dicionario_diagnostico.md').write_text('# Dicionário extraído do banco\n\nDescrições são metadados oficiais do backup, não regras inventadas. O relatório interpreta os campos usados.\n\n'+dictionary+'\n',encoding='utf-8')
    evidence={}
    for name in ['inventory.json','audit.json','followup.json','exceptions.json','pricing_semantics.json','integrity.json','source_manifest.json','environment.json','final_environment.json']:
        evidence[name]=hashlib.sha256((META/name).read_bytes()).hexdigest()
    (META/'report_evidence_hashes.json').write_text(json.dumps(evidence,indent=2),encoding='utf-8')
    print('Report generated; evidence reconciliation assertions passed.')

if __name__=='__main__': main()
