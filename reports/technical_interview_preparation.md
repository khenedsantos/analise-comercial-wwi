# Preparação para discussão técnica

Roteiro de estudo das decisões implementadas. Cada demonstração pode usar um exemplo
pequeno e a leitura dos artefatos existentes, sem reconstruir o banco ou executar cargas.

| Pergunta | Demonstração esperada | Referências |
|---|---|---|
| Qual é o grão da FactInvoiceLine? | Distinguir linha, fatura e pedido; explicar PK, chaves de contexto e InvoiceDate versus OrderDate. | [Modelo](modelo_etapa4.md), [DDL](../sql/01_model.sql) |
| Por que separar Buyer e Billing Account? | Mostrar como 663 compradores e 263 contas respondem a perguntas diferentes; explicar interseção de filtros e concentração por conta. | [Contrato](contrato_analitico_etapa3.md), [Q03/Q04](analise_executiva_powerbi.md) |
| Quais cardinalidades e caminhos de filtro são permitidos? | Diferenciar FKs SQL de propagação no Power BI; desenhar relações diretas e a bidirecionalidade específica produto–ponte, evitando caminhos ambíguos. | [Modelo](modelo_etapa4.md), [model.bim](../powerbi/WWI.SemanticModel/model.bim) |
| Como a BridgeProductGroup evita duplicar valores? | Comparar join ingênuo com união de produtos via EXISTS; explicar sobreposição e por que grupos não são somáveis. Tratar valores inflados como sentinelas. | [SQL de métricas](../sql/02_metrics.sql), [testes SQL](../sql/03_validation.sql), [testes DAX](../powerbi/validacao_desktop.dax) |
| Como os contextos DAX afetam os indicadores? | Localizar ALLSELECTED, numerador e denominador; distinguir slicer, membro visual e total. Explicar BLANK em contextos sem cobertura válida. | [Medidas no modelo](../powerbi/WWI.SemanticModel/model.bim), [contrato](contrato_analitico_etapa3.md) |
| Por que margem é razão de somas? | Construir duas linhas com vendas diferentes e contrastar razão agregada com média de margens; separar vendas sem impostos, faturamento e lucro comercial registrado. | [Contrato](contrato_analitico_etapa3.md), [verificador Decimal](../scripts/verify_stage4.py) |
| Como calcular e interpretar CR5? | Explicar seleção externa, cinco IDs, desempates, denominador e diferenças entre comprador, conta e produto; justificar a inaplicabilidade a Stock Groups. | [SQL Kpis](../sql/02_metrics.sql), [DAX](../powerbi/WWI.SemanticModel/model.bim), [Q04](analise_executiva_powerbi.md) |
| O que sustentam os números de validação? | Rastrear 565 asserts SQL + 42 complementares = 607; separar observações de KPI e os 85 PASS Desktop relatados manualmente. Explicar exatidão monetária versus precisão de razões. | [Evidência SQL](../data/metadata/stage4-20260930-120408.json), [validação SQL](validacao_etapa4.md), [validação BI](validacao_powerbi_final.md) |
| Como interpretar produtos negativos e condições especiais? | Distinguir lucro negativo de crédito, incidência de participação nas vendas; ler a fórmula percentual Microsoft e explicar por que não foi corrigida como desconto convencional. | [Diagnóstico](diagnostico_etapa2.md), [função original](../data/metadata/embedded_modules/Website.CalculateCustomerPrice.sql), [Q05/Q07](analise_executiva_powerbi.md) |
| O que os dados sintéticos não permitem concluir? | Explicar ausência de causalidade e impacto realizado; distinguir mês indisponível de zero e variação de mix de decomposição causal da margem. | [Contrato](contrato_analitico_etapa3.md), [análise executiva](analise_executiva_powerbi.md) |
| Como transformar achados em recomendações defensáveis? | Relacionar perda de margem, SKUs negativos e concentração a investigações; indicar custos, contratos e dados operacionais necessários antes de agir. | [Recomendações](analise_executiva_powerbi.md), [README](../README.md) |

O [índice de evidências](development_decisions_and_evidence.md) reúne referências
e limites de rastreabilidade.
