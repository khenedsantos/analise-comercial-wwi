# Análise Executiva — WWI

## 1. Escopo e evidências

Case concluído de performance comercial e rentabilidade com dados sintéticos Microsoft Wide World Importers. O objetivo é demonstrar raciocínio de negócio apoiado em controles técnicos; não retrata uma empresa real ou resultados profissionais do autor.

Este documento separa **observações**, **interpretações** e **decisões propostas**. Usa as capturas finais do dashboard, os resultados validados informados pelo autor e as evidências históricas de SQL. Não houve nova consulta SQL, execução DAX ou alteração dos dados nesta etapa.

Referências: [contrato analítico](contrato_analitico_etapa3.md), [diagnóstico](diagnostico_etapa2.md), [modelo](modelo_etapa4.md), [validação final](validacao_powerbi_final.md).

## 2. Período e conceitos

O histórico abrange 01/01/2013 a 31/05/2016. A comparação executiva é **Jan–Mai/2016 versus Jan–Mai/2015**; junho–dezembro/2016 são indisponíveis, não zeros. Q04 e Q05 apresentam controles históricos; Q07 distingue explicitamente o histórico do período comparável. A data oficial é InvoiceDate.

Neste documento, UM designa unidade monetária neutra, sem atribuir moeda não documentada. No dashboard final, o sufixo UM foi removido; os valores são reconhecidos pelo contexto e pelas escalas mi/mil. A precisão analítica deste texto foi preservada. Lucro comercial registrado é a soma de LineProfit. Margem é soma do lucro / soma das vendas sem impostos, para a mesma população; não é margem líquida, EBITDA ou margem de contribuição.

## 3. Q01 — Evolução comercial

**Observação.** No comparável, vendas passam de 22.679.145,45 para 22.633.175,55 UM; lucro de 11.337.077,40 para 11.174.765,55 UM. As variações são −45.969,90 UM em vendas (−0,2027%), −162.311,85 UM em lucro e −0,6156 p.p. em margem. As margens exibidas são 49,9890% e 49,3734%.

**Interpretação.** A deterioração da rentabilidade é mais relevante que a pequena oscilação de vendas. O gráfico temporal descreve o comportamento do snapshot; não comprova sazonalidade de uma operação real.

**Decisão proposta.** Priorizar investigação de preços, custos e composição da carteira antes de incentivar crescimento indiscriminado. Acompanhar vendas, lucro e margem em janelas equivalentes.

[Captura Q01](../docs/images/powerbi/01_evolucao.png)

## 4. Q02 — Produtos e variação absoluta do lucro

**Observação.** O maior detrator exibido é `32 mm Anti static bubble wrap (Blue) 50m`, com variação de lucro de −105.560,00 UM. Entre os compensadores, `Chocolate beetles 250g` apresenta +77.611 UM. Os rankings preservam Bottom/Top 10, no contexto de 2016, e a tabela permite investigar os demais produtos.

**Interpretação.** Deterioração de lucro e lucro negativo são fenômenos distintos: um SKU pode perder lucro em relação ao ano anterior e ainda permanecer lucrativo. Os rankings Q02 não devem ser confundidos com a população negativa da Q05.

**Decisão proposta.** Investigar o volume vendido, condições comerciais e margem de cada detrator; entender também os compensadores antes de replicar ações. Não converter a soma de perdas em promessa de recuperação.

[Captura Q02](../docs/images/powerbi/02_produtos.png)

## 5. Q03 — Categorias e compradores

**Observação.** A captura mostra comportamentos diferentes: Computer Store cresce em vendas e margem; Supermarket cresce em vendas e perde margem; Novelty Shop perde vendas e margem. Dentro de uma mesma categoria, o scatter apresenta compradores em diferentes posições. Cada bolha representa comprador; tamanho indica vendas e cor indica categoria.

**Interpretação.** Uma ação uniforme por categoria pode esconder trajetórias individuais distintas. Buyer é o comprador, identificado por CustomerID; não deve ser substituído por BillToCustomerID.

**Decisão proposta.** Separar compradores com perda de vendas, compressão de margem e deterioração simultânea. Priorizar investigação por magnitude e contexto, sem inferir churn, aquisição ou causas comerciais ausentes da base.

[Captura Q03](../docs/images/powerbi/03_clientes.png)

## 6. Q04 — Concentração comercial

**Observação histórica.** CR5 representa vendas dos cinco maiores elementos / vendas da população selecionada, conforme a medida existente.

| Perspectiva | CR5 |
| --- | ---: |
| Comprador | 1,0739% |
| Conta de cobrança | 63,7540% |
| Produto | 21,0290% |

São 663 compradores e 263 contas de cobrança. As contas Tailspin Toys (Head Office) e Wingtip Toys (Head Office) se destacam no ranking de vendas.

**Interpretação.** A concentração é muito maior no nível financeiro de cobrança. Não existe threshold formal que autorize rotular automaticamente o indicador como risco crítico. CR5 não mede inadimplência.

**Decisão proposta.** Monitorar dependência comercial por Billing Account e evolução das principais contas; complementar com contratos e exposição financeira antes de decisões de risco.

[Captura Q04](../docs/images/powerbi/04_concentracao.png)

## 7. Q05 — Linhas com lucro negativo

**Observação histórica.** São 4.626 linhas negativas, 2,0266% das 228.265 linhas, com resultado de −320.493,55 UM. A composição é:

| População | Linhas | Resultado registrado (UM) |
| --- | ---: | ---: |
| Negativas não especiais | 4.114 | −274.500,00 |
| Condições especiais, todas negativas nesta amostra | 512 | −45.993,55 |
| Total negativo | 4.626 | −320.493,55 |

Quatro variantes de `Halloween zombie mask (Light Brown)` concentram as 4.114 linhas não especiais: XL, S, M e L. Os resultados exibidos são −72.372,00, −71.016,00, −67.008,00 e −64.104,00 UM, respectivamente.

**Interpretação.** A concentração permite priorizar revisão de SKUs. O resultado negativo não é lucro líquido, receita perdida, devolução nem ganho potencial recuperável. A participação de condições especiais de **0,0127% refere-se às vendas históricas**, não às linhas negativas.

**Decisão proposta.** Revisar cadastro, preço, custo e viabilidade dos SKUs e dos acordos, preservando a evidência original. Na amostra, o cálculo percentual especial aplica preço-base × percentual / 100. Não interpretar os rótulos 10% e 15% como desconto efetivo convencional.

[Captura Q05](../docs/images/powerbi/05_resultados_negativos.png)

## 8. Q06 — Geografia e controles de mix

**Observação.** A página compara estados no agregado, dentro da categoria de cliente e para os mesmos produtos. Nos controles exibidos, `Air cushion machine (Blue)` tem margem aproximada de 39,9684% e `20 mm Double sided bubble wrap 50m`, de 85,1852%, repetidas entre os estados mostrados. Os produtos e filtros existentes foram mantidos; vendas > 0 já se aplica ao segundo controle.

**Interpretação.** Diferenças agregadas podem refletir produtos e clientes diferentes. Comparar o mesmo SKU e segmento melhora a comparabilidade, mas não comprova ausência de efeito geográfico nem isola frete, contratos ou serviço. Geografia representa a localidade de entrega cadastral do comprador.

**Decisão proposta.** Não classificar estados como bons ou ruins apenas pela margem agregada. Investigar diferenças residuais com custos logísticos e contexto comercial adicionais.

[Captura Q06](../docs/images/powerbi/06_geografia.png)

## 9. Q07 — Condições especiais e mix

**Observação das condições.** No comparável, os dois acordos somam 512 linhas e −45.993,55 UM de resultado. A captura identifica `10% 1st qtr USB Wingtip` e `15% 2nd qtr USB Tailspin`; a página executiva usa seus nomes abreviados. A soma das variações de lucro desses acordos representa cerca de 28% da queda absoluta de 162.311,85 UM. A linha sem condição especial também apresenta queda de lucro.

**Interpretação.** Os acordos são muito negativos nas linhas associadas e contribuem aritmeticamente para a variação observada; não explicam sozinhos toda a deterioração. Essa comparação não estima resultado incremental ou causal de uma política comercial.

**Observação do mix comparável.** Novelty Items apresenta aumento de vendas de 739.290,65 UM e margem aproximada de 36,02%. Packaging Materials apresenta redução de 679.761,55 UM e margem de 51,47%. A tabela estrutural mostra margens diferentes entre grupos no histórico completo.

**Interpretação e limite.** A mudança é compatível com pressão de composição sobre a margem. Stock Groups se sobrepõem: um produto pode estar em mais de um grupo. Há 227 produtos e 442 associações. As participações K11 não são aditivas; não é válido somar grupos nem atribuir contribuição causal em pontos percentuais a partir dessas tabelas.

**Controle técnico.** O join ingênuo gera 450.703 linhas e 275.964.455,10 UM de vendas. O conjunto correto mantém 228.265 linhas e 172.261.341,20 UM. A ponte deve selecionar produtos sem multiplicar a fato; os valores inflados são sentinelas de erro.

[Captura Q07](../docs/images/powerbi/07_mix_condicoes_especiais.png)

## 10. O que eu faria como gestor

| Prioridade | Proposta | Evidência | Acompanhamento |
| --- | --- | --- | --- |
| P1 | Recuperar margem antes de acelerar vendas | Vendas −0,20%, lucro −162,31 mil UM, margem −0,62 p.p. | Vendas, lucro e margem comparáveis |
| P1 | Revisar SKUs com perda estrutural | Quatro SKUs concentram 4.114 negativas não especiais | Resultado e ocorrências negativas por SKU; preço/custo; viabilidade |
| P1 | Reprecificar condições especiais deficitárias | 512 linhas, −45,99 mil UM | Margem sob condição, volume e avaliação futura de resultado incremental |
| P2 | Priorizar compradores conforme deterioração | Trajetórias individuais heterogêneas dentro das categorias | Variação de vendas e margem; lucro por comprador |
| P2 | Monitorar concentração por conta de cobrança | CR5 de contas 63,7540% | CR5 e participação/evolução das maiores contas |

Para SKUs, considerar menor exposição ou descontinuação somente se a economia unitária não puder ser corrigida. Para os acordos USB Wingtip 10% e USB Tailspin 15%, condicionar continuidade a resultado incremental positivo demonstrado com dados adicionais. Nenhuma intervenção foi executada neste case; não se declara ganho realizado.

Os dados permitem identificar padrões e prioridades, mas não comprovam causalidade operacional em todos os casos. Decisões definitivas sobre preço, custo, desconto ou descontinuação exigiriam informações adicionais de custos, contratos e estratégia comercial.

[Captura Q08](../docs/images/powerbi/08_recomendacoes_executivas.png)

## 11. Limitações

Dataset sintético; período final parcial; ausência de notas de crédito observadas; ausência de custos operacionais completos, metas e desenho causal. A fórmula especial pertence ao gerador Microsoft, não a uma operação real. Atributos cadastrais e custos implícitos têm as limitações registradas no diagnóstico. Relações muitos-para-muitos exigem união sem duplicação. Os achados são descritivos e as recomendações são hipóteses gerenciais a validar.

## 12. Próximos dados que eu pediria como gestor

| Dados adicionais | Decisão que apoiariam |
| --- | --- |
| Custos unitários detalhados e sua evolução | Separar custo de produto, despesas e custos operacionais; avaliar viabilidade |
| Regras de formação de preço | Entender preço-base, exceções e margem pretendida |
| Contratos comerciais | Verificar obrigações, vigência e condições de renegociação |
| Motivo das condições especiais | Distinguir promoção, aquisição, retenção, contrapartida e erro cadastral |
| Estoque e giro | Avaliar exposição, capital imobilizado e descontinuação |
| Devoluções e seus vínculos com faturas | Medir reversões e custo de atendimento |
| Frete/logística | Avaliar rentabilidade por localidade após custos de entrega |
| Metas comerciais | Comparar resultado realizado com o plano, além do histórico |
| Aquisição e retenção de clientes | Investigar valor ao longo do tempo e resultado incremental dos acordos |

Esses dados são pedidos futuros, não requisitos coletados de stakeholders ou entrevistas realizadas.
