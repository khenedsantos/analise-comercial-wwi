# Preparação técnica do Power BI

**Estado:** modelo textual preparado e verificado estruturalmente. Abertura completa, atualização, compilação DAX e reconciliação no Desktop: **PENDENTE DE VALIDAÇÃO NO DESKTOP**. Os 607 PASS da Etapa 4 não validam esta tradução para DAX.

## Abrir e atualizar

1. Abra `analise_comercial_wwi.pbip` no Power BI Desktop. A instalação identificada é Store 2.157.1354.0. Habilite suporte a projetos nas opções de visualização, caso essa versão solicite. Não importe `model.bim` como dados: ele é a definição do modelo.
2. Confirme que aparecem as nove tabelas abaixo e `_Medidas`. Se houver erro de abertura, registre o texto completo antes de alterar o modelo. Uma janela “Sem título” não comprova abertura bem-sucedida.
3. Com mais de 3 GiB livres, inicie somente a instância existente: `SqlLocalDB start WWI_Portfolio`. Atualize no Desktop usando autenticação Windows para `(localdb)\WWI_Portfolio`, banco `WWI_Portfolio_Diagnostic`. Não restaure nem execute Build. Abaixo de 2 GiB, interrompa; entre 2 e 3 GiB, evite atualização.
4. Confirme `DimDate[CalendarDate]` como coluna da tabela de datas e Auto Date/Time desabilitado para o arquivo. O modelo contém `dataCategory: Time`, data única e anotação de inteligência temporal automática desativada; a aplicação dessas opções ainda precisa ser confirmada no Desktop.
5. Execute `validacao_desktop.dax` na exibição de consulta DAX. São **85 verificações preparadas, nenhuma executada nesta entrega**. Esperado: 85 linhas, todas PASS. Não arredonde valores para aprovar testes. Erro de compilação ou qualquer FAIL impede o aceite. Preserve/exporte o resultado para revisão.
6. Ao terminar a atualização, execute `SqlLocalDB stop WWI_Portfolio`. Não deixe a instância aberta após o trabalho. Salve como projeto textual; não publique PBIX.

A abertura pelo shell do Windows foi solicitada nesta retomada e iniciou o Desktop, mas não comprovou carga do WWI. O provedor COM MSOLAP retornou “Provedor não encontrado”; as DLLs Store já haviam sido inacessíveis. Não foram instaladas ferramentas nem automatizados cliques. A conclusão no Desktop é manual; não há resultados semânticos inferidos da validação de JSON.

## Fonte, modelo e filtros

Import exclusivamente das tabelas materializadas `analytics`: `FactInvoiceLine`, `DimDate`, `DimBuyer`, `DimBillingAccount`, `DimGeography`, `DimProduct`, `DimStockGroup`, `BridgeProductGroup`, `DimSpecialDeal`. `_Medidas` é uma tabela local de uma linha, sem relação. Não se importam `MonthlyControl`, a saída de `Kpis` ou tabelas OLTP.

Seis relações ativas 1→* ligam Data, Comprador, Conta, Geografia, Produto e Acordo à fato por suas chaves. Grupo 1→* Bridge; Produto 1↔* Bridge é a **única relação bidirecional**. Não existe relação Comprador–Geografia nem Bridge–Fato. `SpecialDealID` nulo é legítimo: as linhas não especiais permanecem na população.

A ponte transmite a **união** de produtos, sem multiplicar linhas, ratear valores ou criar grupo principal. Produtos e grupos selecionados se intersectam. Subtotais de grupos se sobrepõem; o total deve ser recalculado. A consulta preparada compara os conjuntos de InvoiceLineID propagados e obtidos por união explícita para grupos 7/8, todos os grupos e grupo vazio 5, além da interseção produto/grupo. As sentinelas incorretas 450.703 linhas / 275.964.455,10 vendas são rejeitadas pelos controles globais.

Comprador e conta de cobrança são perspectivas separadas; filtros simultâneos intersectam a fato. Geografia/categoria continuam sendo do comprador. IDs e valores brutos da fato estão ocultos; flags diagnósticas, atributos e medidas ficam disponíveis. IDs continuam acessíveis em DAX para testar identidade e desempate. Nomes não únicos não substituem IDs em agrupamentos de entidades.

## Medidas e contrato

60 definições DAX, das quais 17 auxiliares ocultas; pastas de medidas por finalidade. Valores monetários usam decimal fixo (`Currency.Type`/`decimal`) e formato **UM**, sem presumir moeda. Flags usam booleanos e `KEEPFILTERS` nos diagnósticos. Contagens e somas vazias dentro da cobertura retornam zero; razões inválidas retornam BLANK.

| Contrato | Medidas no modelo |
|---|---|
| K01–K04 | Vendas sem impostos; Impostos; Faturamento com impostos; Lucro comercial registrado |
| K05 | Margem comercial registrada — razão das somas |
| K06–K09 | Faturas; Clientes compradores; Contas de cobrança; Produtos faturados — distintos na fato |
| K10 | Valor médio do recorte por fatura |
| K11 | Participação — sete variantes explícitas: comprador, conta, produto, grupo, cidade, categoria, grupo comprador |
| K12 | CR5 — comprador, conta, produto; desempate por ID crescente |
| K13–K16 | Variação de vendas, crescimento de vendas, variação de lucro, variação de margem; variantes AUTO/YOY/MOM/YTD |
| K17–K21 | Linhas de lucro negativo; Percentual de linhas negativas; Resultado registrado das linhas negativas; Linhas em condições especiais; Participação das condições especiais |
| Controles adicionais | Linhas faturadas; Negativas não especiais |

**Escalas:** percentuais DAX são frações com formato percentual; SQL retorna 0–100. A consulta de validação multiplica essas frações por 100. K16 já retorna pontos percentuais e não usa formato percentual. Dinheiro/contagens exigem igualdade exata; limites para razões refletem a precisão SQL documentada, não ajuste de resultado.

**K11/K12 e futura interface:** escolha a variante correspondente ao eixo. `ALLSELECTED` atua somente no ID/nome desse eixo; demais filtros permanecem. Não aplicar Top N nativo nem um filtro externo dos cinco vencedores: isso pode reduzir a base S. A exibição restrita ao Top 5 ainda precisa ser projetada e testada mantendo S, conforme o [contrato](../reports/contrato_analitico_etapa3.md). As medidas estão preparadas para seleção e eixo completos; não há garantia para qualquer combinação futura de hierarquias, campos ou filtros visuais. CR5 de grupos não existe.

**Tempo:** calendário da origem 01/01/2013–31/05/2016; sem TODAY. AUTO usa YoY para mês único, YTD para janeiro até mês completo; demais intervalos não recebem comparador. MoM é explícito. Anos completos e fevereiro bissexto mantêm os intervalos civis. Seleções parciais/descontínuas e anteriores à cobertura não recebem comparação. Nunca estender o calendário ou apresentar junho–dezembro/2016 como zero. O modelo enxerga as datas efetivamente presentes: um pedido externo parcialmente fora da cobertura não é detectável depois de recortado pelo calendário; a futura interface deve restringir escolhas à cobertura, sem truncamento silencioso.

## Verificação e manutenção

`python powerbi/verify_preparation.py` verifica estrutura, relações, tipos, referências, sintaxe Python, hashes protegidos e correspondência da consulta com a evidência congelada. **Não compila DAX nem substitui o Desktop.** Resultado nesta retomada: verificações estruturais OK; todas as validações Power BI × SQL e da bridge permanecem pendentes.

Os 14 controles obrigatórios estão incluídos na consulta (margem usa valor preciso, com apresentação esperada 49,7669%). Também há comparações temporais, flags, participação, CR5 e conjuntos da bridge. Os esperados vêm de `data/metadata/stage4-20260930-120408.json` e dos controles aprovados; não houve reexecução SQL. Os 45 pares SQL não foram repetidos.

`build_model.py` é o gerador existente; **não o execute depois de edições manuais no Desktop sem revisar**, pois sobrescreve definições textuais. `verify_preparation.py --generate` regenera apenas a consulta técnica. O relatório PBIR contém uma página técnica vazia `00_Validação`, sem visuais ou dashboard. A estrutura inclui `definition/version.json` (versão 2.0.0, conforme exemplo oficial Microsoft BCApps), `report.json`, índice e definição da página. Os sete JSON de estrutura passaram nos schemas oficiais; isso não comprova abertura ou carga no Desktop.

Referências: [modelo SQL](../reports/modelo_etapa4.md), [contrato normativo](../reports/contrato_analitico_etapa3.md), [validação SQL histórica](../reports/validacao_etapa4.md), [formato oficial PBIP](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-overview), [modelo textual TMSL/model.bim](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-dataset).

Depois do aceite técnico, Khened + ChatGPT definirão visuais, UX, análise Q01–Q07 e interpretações. Sem commit, push, PR ou mudança da main nesta preparação.
