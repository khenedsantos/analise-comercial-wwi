# Etapa 3 — Definições analíticas e contrato de métricas

**Projeto:** Performance Comercial e Rentabilidade: análise de faturamento, margem e concentração de carteira.

**Versão:** 1.0, 30/09/2026. Contrato fechado para o snapshot aprovado; alterações futuras exigem versionamento e reconciliação. Não especifica esquema dimensional físico nem implementa transformações, medidas DAX ou análises comerciais finais.

**Natureza das afirmações:** **[FATO]** evidência da Etapa 2; **[MICROSOFT]** regra no código oficial; **[DECISÃO]** convenção analítica deste projeto. O [diagnóstico da Etapa 2](diagnostico_etapa2.md) permanece como registro histórico. Este documento fecha suas propostas, sem alterar fatos. É a referência normativa das métricas; README é apenas orientação de navegação.

## 1. Retomada e evidências preservadas

Foram inspecionados os 19 arquivos de trabalho encontrados: README, `.gitignore` e os 17 arquivos em `scripts/`. Todos estavam legíveis; os Python passaram por análise sintática. Foram conferidos os nove hashes em `data/metadata/report_evidence_hashes.json`, todos íntegros. Não havia documento da Etapa 3 salvo. O trabalho existente correspondia à Etapa 2 concluída, incluindo seus três relatórios e resultados SQL.

Em 30/09/2026, `SqlLocalDB info WWI_Portfolio` confirmou **Parado**, com último início em 29/09/2026 às 15:51:14. A leitura exigiu sair da sandbox para acessar o registro; não iniciou a instância. O arquivo `final_environment.json` registra a parada normal anterior. Nenhuma consulta ao banco foi executada nesta etapa, nem novo download ou restauração.

## 2. População analítica oficial

**[DECISÃO] P0 — população de referência:** todas as linhas de `Sales.InvoiceLines` do backup oficial aprovado, vinculadas exatamente uma vez a `Sales.Invoices` por `InvoiceID`, com `IsCreditNote=0` e `InvoiceDate` entre **01/01/2013 e 31/05/2016**, inclusive. Grão analítico: **uma linha original por `InvoiceLineID`**. Fatura é documento distinto por `InvoiceID`; pedido é outro evento.

Snapshot: `WideWorldImporters-Standard.bak`, release `wide-world-importers-v1.0`, asset 80319902, SHA-256 `066279a8cd28c8d85cbd8215ea71a5d672b420cfbc19756b635c27bd8027dada`. Fonte e licença permanecem no [manifesto](../data/metadata/source_manifest.json).

**Incluem-se** todas as linhas com lucro negativo, as condições especiais de preço, todos os clientes/produtos faturados e as faturas sem confirmação de entrega. Não se exige pagamento, entrega confirmada, marca preenchida ou vínculo a Buying Group. Não se excluem extremos para melhorar resultados. Os 3.085 pedidos sem fatura não são vendas faturadas e não entram em P0.

**[FATO]** Neste snapshot todas as linhas faturadas satisfazem P0; não há notas de crédito. O filtro de escopo não autoriza descartar silenciosamente documentos futuros: um snapshot diferente, crédito, órfão ou data fora da janela deve disparar revisão do contrato antes da carga. Rejeição técnica não deve ser convertida em perda silenciosa de linhas.

### Controles obrigatórios sem filtros

| Controle | Valor de referência |
| --- | --- |
| Linhas faturadas distintas | 228.265 |
| Faturas distintas | 70.510 |
| Vendas sem impostos | 172.261.341,20 |
| Impostos | 25.782.098,25 |
| Faturamento com impostos | 198.043.439,45 |
| Lucro comercial registrado (`LineProfit`) | 85.729.180,90 |
| Margem comercial registrada, exibição com 4 casas | 49,7669% |
| Linhas com `LineProfit < 0` | 4.626 |
| Linhas em condições especiais | 512 |
| Notas de crédito observadas | 0 |
| Clientes compradores / contas de cobrança | 663 / 263 |
| Produtos faturados | 227 |

Margem não é armazenada como constante de 49,7669%: é recalculada pela razão exata dos totais e arredondada apenas para exibição. Valores monetários são **UM — unidades monetárias da base**; não converter para BRL ou presumir moeda como campo registrado.

## 3. Contexto de cálculo e regras comuns

**[DECISÃO]** Para cada linha `l`, definir apenas conceitualmente:

- `v(l) = ExtendedPrice − TaxAmount`: venda sem impostos.
- `t(l) = TaxAmount`; `b(l) = ExtendedPrice`; `p(l) = LineProfit`.
- `F`: conjunto de IDs únicos de P0 após filtros explícitos (período de faturamento, comprador, conta, produto, geografia do comprador, categoria de cliente, grupo comprador, Stock Groups e indicadores diagnósticos).
- `V(F)=Σv(l)`, `T(F)=Σt(l)`, `B(F)=Σb(l)`, `L(F)=Σp(l)`; somar sobre IDs únicos em F.
- `N(F)=quantidade de InvoiceLineID distintos`; `I(F)=quantidade de InvoiceID distintos com pelo menos uma linha em F`.
- `Neg(F)={l em F: p(l)<0}`; `Esp(F)={l em F: condição especial confirmada pela regra da seção 6}`.

**Precisão:** manter valores de origem decimais; reconciliar somas em centavos sem tolerância arbitrária. Não arredondar razões por linha para depois agregá-las. Divisões com denominador zero, negativo ou período de comparação indisponível retornam **não aplicável (N/A)**, nunca infinito ou zero artificial. Valores de contagem e soma em seleção vazia **dentro da cobertura** são zero; razões são N/A. Períodos fora da cobertura são indisponíveis, inclusive somas.

**Filtros:** todos os KPIs respeitam F, salvo a alteração explicitamente indicada na fórmula (comparação temporal ou denominador de participação). O padrão não aplica filtro de lucro, condição especial, marca ou entrega. A interface futura deverá mostrar período e filtros ativos. Filtrar lucro negativo ou condição especial cria uma **visão diagnóstica rotulada**, sem substituir o total oficial.

**Contagens e tickets sob filtro de produto/grupo:** contam as faturas que contêm as linhas selecionadas e somam somente essas linhas; não recuperam silenciosamente os demais itens da fatura. O ticket nesse contexto se chama **valor médio do recorte por fatura**, para não sugerir ticket integral. Contagens distintas, tickets e margens não são aditivos entre produtos/grupos.

**Base selecionada S:** para participação e concentração, S contém P0 com filtros externos ativos, antes de acrescentar o membro da linha visual e antes de restringir ao Top 5. Uma seleção explícita de clientes/produtos delimita S e permanece no denominador; o rótulo será “na seleção”. Outros filtros, inclusive período, diagnóstico e Stock Groups, permanecem. Não remover todos os filtros indiscriminadamente.

## 4. Dicionário definitivo de KPIs — versão 1.0

Todas as linhas abaixo herdam a população, os filtros, precisão, regra de N/A e interpretação de recortes da seção 3. “Sem denominador” significa soma/contagem, não razão. Grão de origem sempre permanece o item faturado; o grão de apresentação pode ser o período/recorte declarado. As medidas de controle não implicam a criação de cartões ou páginas adicionais.

### Medidas centrais e de controle

| ID / nome oficial | Fórmula e denominador | Granularidade de cálculo | População e filtros específicos | Interpretação permitida / proibida |
| --- | --- | --- | --- | --- |
| K01 Vendas faturadas sem impostos | `V(F)`; sem denominador | Soma de linhas | F; sem exclusões adicionais | Valor dos itens faturados sem impostos / não caixa, GMV externo ou vendas líquidas contábeis completas |
| K02 Impostos faturados | `T(F)`; sem denominador | Soma de linhas | F | Tributo registrado na amostra / não imposto sobre lucro ou prova de conformidade fiscal |
| K03 Faturamento com impostos | `B(F)`; sem denominador | Soma de linhas | F | Total cobrado registrado / não somar a K01 nem chamar de venda sem impostos |
| K04 Lucro comercial registrado | `L(F)`; sem denominador | Soma assinada de linhas | F, incluindo negativos | Resultado registrado sobre custo de produto / não lucro líquido, EBITDA ou margem de contribuição |
| K05 Margem comercial registrada | `100 × L(F)/V(F)`; denominador K01 | Razão entre somas do recorte | Mesmo F no numerador e denominador | Percentual de lucro registrado sobre vendas / não média das margens individuais; pode ser negativa |
| K06 Faturas de venda | `I(F)`; sem denominador | InvoiceID distinto | F, ao menos uma linha selecionada | Documentos com venda no recorte / não número de pedidos ou número de linhas |
| K07 Clientes compradores com faturamento | `distinct CustomerID(F)`; sem denominador | CustomerID distinto da fatura | F | Compradores observados / não clientes adquiridos, retidos ou cadastrados sem compra |
| K08 Contas de cobrança com faturamento | `distinct BillToCustomerID(F)`; sem denominador | BillToCustomerID distinto da fatura | F | Destinatários de cobrança observados / não clientes compradores nem grupo econômico inferido |
| K09 Produtos faturados | `distinct StockItemID(F)`; sem denominador | Produto distinto | F | Produtos observados no recorte / não variedade total disponível em estoque |
| K10 Ticket médio por fatura | `V(F)/I(F)`; denominador K06 | Razão do recorte por documento | F; aplicar rótulo “valor médio do recorte por fatura” sob filtro de itens | Valor médio faturado / não ticket por pedido nem valor integral da cesta sob filtro parcial |
| K11 Participação nas vendas selecionadas | `100 × V(S ∩ e)/V(S)`; denominador vendas em S | Membro e de um eixo identificado | Numerador acrescenta e; denominador remove apenas o membro visual e o Top 5 | Participação na seleção / não participação de mercado; Stock Groups podem se sobrepor |
| K12 Concentração Top 5 de vendas (CR5) | `100 × Σ V(S ∩ e)` dos 5 primeiros / `V(S)` | Eixo exclusivo: comprador, conta OU produto | Ranking em S antes do Top 5; receita decrescente, ID crescente para desempate | Concentração descritiva / não limite de risco ou meta; proibido CR5 de Stock Groups |

**K12:** exatamente cinco IDs, ou todos se houver menos de cinco; seleção não vazia com menos de cinco retorna 100%. Contas, compradores e produtos geram três perspectivas da mesma definição, sem mistura entre eixos. Top 5 é uma convenção descritiva, não um limiar de negócio. O total fora do Top 5 não desaparece do denominador. Em S vazio, resultado N/A.

### Comparações temporais

`F0` e `F1` aplicam **os mesmos filtros não temporais** aos períodos anterior e atual elegíveis (seção 8). A carteira observada em cada período permanece completa; não impor painel fixo de clientes/produtos. Rankear separadamente quando necessário e nunca trocar a população entre numerador e denominador silenciosamente.

| ID / nome oficial | Fórmula e denominador | Granularidade | População e filtros específicos | Interpretação permitida / proibida |
| --- | --- | --- | --- | --- |
| K13 Variação absoluta de vendas | `V(F1) − V(F0)`; sem denominador | Dois períodos comparáveis | F1 e F0; ambos com cobertura | Mudança observada em UM / não impacto de uma ação |
| K14 Crescimento das vendas | `100 × (V(F1) − V(F0))/V(F0)`; base K01 anterior | Dois períodos comparáveis | Mesmos filtros; base positiva | Crescimento descritivo / não crescimento real de mercado ou causalidade; base zero gera N/A |
| K15 Variação absoluta do lucro registrado | `L(F1) − L(F0)`; sem denominador | Dois períodos comparáveis | F1 e F0, preservando sinais | Mudança em UM mesmo com base negativa / não crescimento percentual do lucro |
| K16 Variação da margem registrada | `100 × [L(F1)/V(F1) − L(F0)/V(F0)]`; duas bases de vendas | Dois períodos comparáveis | As duas margens precisam ser válidas | Diferença em pontos percentuais / não variação percentual da margem |

K13 e K15 podem comparar zero observado dentro da cobertura; K14 não divide por zero. Sem cobertura anterior, as quatro são N/A. Não se define crescimento percentual de lucro nesta versão, evitando interpretação inadequada em bases negativas.

### Diagnósticos de composição, sem exclusão do total

| ID / nome oficial | Fórmula e denominador | Granularidade | População e filtros específicos | Interpretação permitida / proibida |
| --- | --- | --- | --- | --- |
| K17 Linhas de lucro negativo | `N(Neg(F))`; sem denominador | Linha distinta | F mais `LineProfit<0` | Frequência absoluta de itens com resultado negativo / não notas de crédito nem faturas deficitárias |
| K18 Percentual de linhas de lucro negativo | `100 × N(Neg(F))/N(F)`; denominador todas as linhas de F | Razão de contagens de linha | Só o numerador recebe o predicado negativo; filtros explícitos de F são mantidos | Incidência por item / não proporção de receita, clientes ou faturas negativas |
| K19 Resultado registrado nas linhas negativas | `Σ p(l)` sobre Neg(F); sem denominador | Soma assinada das linhas negativas | F mais `LineProfit<0` | Componente negativo de K04, apresentado com sinal negativo / não prejuízo líquido ou ganho recuperável |
| K20 Linhas em condições especiais de preço | `N(Esp(F))`; sem denominador | Linha distinta com evidência de elegibilidade | F mais indicador definido na seção 6 | Itens associados aos acordos auditados / não todos os itens negativos nem descontos inferidos pelo sinal |
| K21 Participação das condições especiais nas vendas | `100 × V(Esp(F))/V(F)`; denominador K01 de F | Razão entre somas de linhas | Só o numerador acrescenta a condição especial | Composição das vendas observadas / não efeito do desconto sobre receita ou lucro |

Com filtro explícito “somente negativas”, K18 é 100%; com “somente especiais”, K21 é 100%, se denominadores positivos. Não contornar esse contexto silenciosamente. Para medir participação na população completa, retirar explicitamente o filtro diagnóstico e indicar isso ao leitor.

**Medidas não promovidas a KPIs ativos:** créditos (controle observado zero), vendas líquidas de créditos (equivalência atual, não medida distinta), quantidades somadas entre embalagens diferentes, taxa efetiva de desconto, percentual de contribuição ao lucro quando a base pode ser negativa, metas, ROI, CAC, LTV, churn, market share e margens contábeis não sustentadas.

## 5. Cliente comprador, cobrança e classificações

**[DECISÃO]** `CustomerID` **da fatura** é a identidade padrão da carteira comercial (K07, análises de clientes, categoria, grupo comprador e geografia de entrega do comprador). `BillToCustomerID` **da fatura** é uma perspectiva alternativa, rotulada “conta de cobrança” (K08 e CR5 por conta). Não substituir os IDs históricos da fatura pelo relacionamento atual do cadastro.

Não somar 663 compradores e 263 contas como se fossem 926 clientes; tampouco deduplicar compradores pelo BillTo. Quando filtrar ambos, aplicar a interseção das linhas. Comparações entre concentração por comprador e por conta devem usar a mesma população F; só o agrupamento muda. Geografia/categoria continuam sendo **do comprador**, mesmo na visualização agrupada por conta, com rótulo explícito. Não atribuir automaticamente o segmento da conta a todas as suas lojas/clientes.

Categoria de cliente é `CustomerCategory`, não `BuyingGroup`. Os 261 sem Buying Group podem receber rótulo de apresentação “Sem grupo comprador”, preservando NULL e seu significado. Não tratar como cliente sem categoria. Marca, cor e tamanho ausentes não autorizam excluir vendas. Categorias cadastradas sem transações não devem ser usadas como evidência de queda de vendas.

No snapshot, cidade/categoria/grupo comprador auditados não divergem entre versões do cliente; aceitar o cadastro atual para esses atributos **somente com o teste de equivalência histórica**. A decisão de armazenamento/historização física fica para a modelagem. A identidade de cobrança da fatura continua obrigatória independentemente dessa simplificação.

## 6. Condições especiais e lucro negativo

**[FATO/MICROSOFT]** Existem 512 linhas associadas aos acordos 1 e 2: 301 e 211, respectivamente, em 14 produtos; todas têm lucro negativo. A função oficial calcula preço-base × percentual/100. Os rótulos de 10% e 15% não significam, nessa implementação, redução de 10% e 15%. Há 4.626 linhas negativas no total, em 18 produtos; portanto os dois conjuntos não são equivalentes.

**[DECISÃO]** As 512 linhas integram integralmente P0 e todos os KPIs padrão. Identificação futura deve reproduzir a [consulta auditada](../scripts/pricing_semantics.sql): linha → fatura → pedido; **OrderDate** dentro da vigência inclusiva do acordo; grupo comprador elegível; produto associado ao Stock Group do acordo; preço cadastral vigente na data do pedido, com início inclusivo e fim exclusivo. O preço realizado deve reconciliar com a fórmula percentual da fonte. Não detectar a condição apenas por preço baixo, `LineProfit<0`, produto ou data de faturamento.

Registrar a associação por `InvoiceLineID` e acordo, sem multiplicar a linha-base. Se nova origem produzir múltiplos acordos elegíveis, tratar como conflito a resolver antes da carga, não escolher arbitrariamente um. Os acordos atuais são disjuntos; a regra de grupo comprador está respaldada pela equivalência histórica verificada. `InvoiceDate` continua sendo a data de contabilização analítica; `OrderDate` serve apenas à identificação da condição de preço.

As 4.626 negativas também permanecem integralmente nos totais. Marcar `LineProfit<0` sem alterar sinal. K19 no snapshot é **−320.493,55**; é componente do lucro agregado, não estimativa de recuperação. Uma fatura com linha negativa pode ter lucro total positivo: não chamar 4.494 faturas que contêm essas linhas de “faturas com prejuízo”.

São permitidos recortes descritivos “especiais” versus “demais” e “negativas” versus “não negativas”, sempre rotulados e reconciliáveis com o total. Não recalcular um preço “corrigido”, remover linhas do baseline, imputar desconto convencional, simular ganho ou atribuir a inconsistência a decisão de uma empresa real. Nenhum cenário contrafactual fica definido nesta etapa.

## 7. Stock Groups: relação muitos-para-muitos

**[FATO]** 227 produtos, 442 associações: 94 em um grupo, 51 em dois e 82 em três. Junção ingênua gera 450.703 linhas e vendas de 275.964.455,10, ambos incorretos como total global.

**[DECISÃO]** Stock Groups permanecem **rótulos sobrepostos**, nunca categorias exclusivas. Nenhum grupo principal, prioridade arbitrária ou rateio é criado. O conjunto físico de produtos/grupos não é substituído por uma taxonomia inventada.

- Selecionar vários Stock Groups significa **união (OU)** dos produtos correspondentes, contando cada `InvoiceLineID` uma única vez. Seleção de produto e de grupo combina-se por interseção.
- Uma linha visual de grupo mede as linhas únicas daquele grupo. Um produto pode aparecer em várias linhas visuais; portanto subtotais por grupo **não são aditivos**. Rodapé e total devem recalcular a união, nunca somar as linhas apresentadas.
- K11 por grupo usa a mesma base S; sua soma pode superar 100%. Exibir “grupos sobrepostos; percentuais não somáveis”. Não apresentar como pizza, partição de mix, waterfall aditivo ou Pareto acumulado de grupos.
- CR5/K12 usa somente IDs exclusivos de comprador, conta ou produto. Decomposições aditivas usam produtos ou outra partição comprovadamente exclusiva, não Stock Groups.
- Nenhum grupo selecionado = ausência desse filtro, não conjunto vazio. Selecionar apenas um grupo cadastrado sem produtos resulta em zero somas/contagens e razões N/A, dentro da cobertura temporal.

O contrato estabelece o comportamento; a forma de implementar relacionamentos e propagação de filtros será decidida na Etapa 4, depois de autorizada.

## 8. Regras temporais

**[DECISÃO]** Data oficial é `InvoiceDate`, calendário **civil**, sem deslocamento de fuso em um campo de data. Cobertura fechada em 31/05/2016, não em TODAY(). Preservar todos os 41 meses. Data de download, criação do backup e atualização cadastral não substituem data de venda.

| Uso | Regra oficial |
| --- | --- |
| Recorte executivo inicial | 01/01/2016–31/05/2016 versus 01/01/2015–31/05/2015 |
| Anos completos | 2013, 2014 e 2015; comparações anuais 2014/2013 e 2015/2014 |
| Mensal YoY | Mesmo mês do ano anterior; disponível desde janeiro/2014 até maio/2016 |
| Mensal MoM | Mês civil completo imediatamente anterior, desde fevereiro/2013; não substituir mês ausente por “linha anterior” |
| Acumulado civil | Janeiro até o último mês completo selecionado; mesma faixa de meses no ano anterior; janeiro–maio para 2016 |
| Seleção descontínua/parcial | Totais descritivos válidos; indicadores temporais automáticos N/A. Comparação customizada exige explicitar e validar ambos os intervalos antes de ser adicionada ao contrato |
| Limites sem comparador | 2013 não tem YoY; janeiro/2013 não tem MoM; junho–dezembro/2016 são indisponíveis, não zero |

Todos os meses da cobertura são completos em relação ao padrão observado: os únicos 178 dias sem documentos são domingos. Isso não prova completude externa de uma empresa real. Calendário futuro deve conter os domingos e dias sem movimento; não excluí-los para esconder lacunas. Fevereiro/2016 tem 29 dias, e meses variam em número de sábados/dias de atividade: não corrigir valores nem supor exposição idêntica.

Para seleção de um único mês, a comparação padrão é YoY; MoM precisa de rótulo explícito. Para acumulado, períodos devem começar em janeiro; para comparações anuais, exigir 12 meses. Não comparar todo 2016 com todo 2015. Usar os mesmos filtros não temporais nos dois lados, sem excluir clientes/produtos presentes somente em um lado.

A documentação WWI descreve ano fiscal iniciado em novembro; o projeto deliberadamente usa ano civil e assim o rotula. O gerador possui multiplicadores anuais e regras de fim de semana; permitir descrição temporal, proibir alegações de crescimento real de mercado, sazonalidade comprovada ou efeito causal de ações.

## 9. Sete perguntas oficiais de negócio

Perguntas autorais para investigar dados sintéticos; não requisitos inventados de entrevistados. Não há respostas comerciais finais nesta etapa.

| ID | Pergunta oficial | Métricas/evidências e limite |
| --- | --- | --- |
| Q01 | Como vendas, lucro e margem registrados evoluem em períodos comparáveis? | K01, K04, K05, K13–K16; ressaltar gerador e cobertura |
| Q02 | Quais produtos compõem a variação absoluta de lucro entre esses períodos? | K04/K15 por StockItemID; somar diferenças inclusive entradas/saídas; associação contábil, não causa |
| Q03 | Como se distribuem vendas e margem por comprador e categoria de cliente? | K01, K05, K07, K10, K11; comparar métricas contínuas, sem inventar faixas de “alta receita” ou “margem aceitável” |
| Q04 | Como muda a concentração de vendas ao considerar compradores, contas de cobrança e produtos? | K11/K12, K07–K09; mesma população, eixos separados |
| Q05 | Como as linhas de lucro negativo compõem o resultado registrado, distinguindo condições especiais e demais vendas? | K04, K17–K21; conjuntos se sobrepõem; não somar negativas + especiais como categorias exclusivas |
| Q06 | Como diferem receita e margem entre localidades, ao observar produtos e segmentos comparáveis? | K01, K05, K06/K07/K09 como suporte; geografia do comprador; usar interseção de produtos/segmentos e mostrar cobertura excluída; sem causalidade ou inferência estatística não testada |
| Q07 | Como mudanças na composição por produto e os preços especiais registrados se relacionam com a margem agregada? | K01, K04, K05, K11 por produto, K20/K21; custos implícitos constantes nesta amostra; método exato de decomposição ainda sujeito à Etapa 4/analítica, sem estimar efeito de desconto |

Créditos/devoluções saem das perguntas oficiais por ausência de observações. Preços especiais tornam-se diagnóstico contextualizado, e não tese sobre política comercial. Não haverá metas, análise principal por marca, inflação de custos ou recomendações de cortes de produtos inferidas apenas de lucro negativo.

## 10. Contratos/testes de aceitação do futuro modelo

**Especificações, não testes já executados em um modelo inexistente.** Os resultados da Etapa 2 são as referências. Testes de soma monetária devem fechar exatamente em centavos; razões são comparadas antes de arredondar, e sua exibição é testada separadamente. A implementação deverá produzir evidência por teste, sem registrar “passou” apenas pela existência desta tabela.

| ID | Contrato e critério de aprovação |
| --- | --- |
| C01 Fonte e população | SHA-256/snapshot fixos; conjunto de InvoiceLineID idêntico a P0, sem IDs adicionais ou perdidos; qualquer nova origem exige revisão |
| C02 Grão e chaves | 228.265 IDs de linha únicos, 70.510 InvoiceID distintos; zero PK nula; atributos de cabeçalho únicos por InvoiceID; impedir junção de itens apenas por OrderID |
| C03 Integridade referencial | Zero órfãos nas relações utilizadas; nenhuma linha perdida por inner joins; versões temporais correspondem no máximo uma vez e cobrem todas as linhas necessárias |
| C04 Totais financeiros | K01=172.261.341,20; K02=25.782.098,25; K03=198.043.439,45; K04=85.729.180,90; K01+K02=K03 globalmente e por fatura, mês e produto |
| C05 Semântica financeira | v=ROUND(Quantity×UnitPrice,2); TaxAmount pela fórmula oficial; total=v+imposto. Preservar LineProfit original; último custo atual pode servir de verificação deste snapshot, nunca substituir silenciosamente o lucro histórico |
| C06 Margem e precisão | K05 em percentual=100×K04/K01; exibir 49,7669% no baseline; total ponderado por vendas, não média de percentuais; denominadores inválidos=N/A |
| C07 Sinais e negativos | 4.626 linhas negativas; soma assinada −320.493,55; Neg e não Neg disjuntos e união=P0; suas somas recompõem K04; proibir ABS no armazenamento da medida |
| C08 Condições especiais | Exatamente 512 IDs únicos (301 acordo 1; 211 acordo 2), usando elegibilidade e preço histórico; 512 pertencem a Neg; 4.114 negativas não especiais; nenhuma duplicação ao atribuir condição |
| C09 Créditos | Zero IsCreditNote=1 nesta origem; se aparecer um, falhar no contrato de snapshot e solicitar revisão de sinais/semântica, não converter em venda normal ou apagá-lo |
| C10 Identidade de cliente | 663 CustomerID e 263 BillToCustomerID observados; usar IDs da fatura; alternar agrupamento conserva receita/lucro; filtros simultâneos intersectam, não unem |
| C11 Ponte de grupos | 227 produtos, 442 pares únicos; distribuição 94/51/82 em 1/2/3 grupos; zero produto sem grupo; selecionar todos os grupos recompõe exatamente P0 |
| C12 União dos grupos | Para quaisquer A/B com interseção: V(A∪B)=V(A)+V(B)−V(A∩B); mesma identidade para contagens de linhas e somas financeiras; IDs duplicados nunca reaparecem no total. 450.703 linhas/275.964.455,10 são sentinelas de join incorreto, não resultados aceitáveis |
| C13 Filtros e denominadores | K11 usa S, mantendo filtros externos e retirando apenas membro visual/Top 5; teste com seleção explícita de clientes e de produtos; CR5 limitado a eixos exclusivos, desempate por ID, base anterior ao Top 5 |
| C14 Não aditividade | Faturas/clientes/produtos distintos, ticket e margem são recalculados no total. Sob filtro de produto, K10 usa somente valor desse recorte/faturas que o contêm; não recuperar cesta integral |
| C15 Tempo | 41 meses, limites auditados; 2013–2015 com 12 meses, 2016 com 5; meses/dias sem venda dentro da cobertura são zero, fora dela indisponíveis; janeiro–maio/2016 compara apenas janeiro–maio/2015 |
| C16 Bordas temporais | Janeiro/2013 sem MoM e 2013 sem YoY; crescimento com base zero=N/A; seleção descontínua/parcial sem comparação automática; bissexto preservado; não usar data corrente |
| C17 Classificações | Preservar 261 clientes sem Buying Group; não confundir com categoria ausente; nulos opcionais não excluem vendas. Validar equivalência histórica dos atributos aceitos no cadastro atual |
| C18 Reconciliação de partições | Por mês civil, produto ou comprador: somas recompõem baseline; por grupos sobrepostos não exigir soma de subtotais=total. Especial/demais e negativo/não negativo são duas partições separadas: não somar suas quatro margens como se fossem classes mutuamente exclusivas. O cruzamento dos dois indicadores é permitido, preservando IDs únicos |
| C19 Rastreabilidade e leitura | Toda saída futura identifica período, filtros, papel do cliente, UM, natureza sintética e ressalva de preço quando aplicável; cada KPI aponta a seu ID neste contrato |

Casos pequenos para testar comportamento de filtros, empates, zero e sobreposição poderão usar fixtures claramente identificadas como **dados de teste**, sem serem adicionadas ao dataset ou apresentadas como resultados da WWI. A Etapa 3 não cria essas fixtures nem a implementação dos testes.

## 11. Decisões fechadas e pendências delimitadas

**Fechadas:** P0 e seus controles; 21 definições de medidas (12 centrais/controle, 4 temporais e 5 diagnósticas); comprador como identidade padrão; conta como perspectiva separada; união de grupos com sobreposição; preservação integral dos 512 especiais e 4.626 negativos; calendário civil e recortes comparáveis; sete perguntas; 19 contratos de aceitação. Créditos ficam como controle zero e limite de generalização. “Vendas líquidas de créditos” coincide com K01 apenas nesta versão e não se torna KPI duplicado.

**Não há decisão analítica básica pendente que impeça encerrar a Etapa 3.** Permanecem para etapas autorizadas futuras: desenho físico dimensional e implementação da ponte/flags; método exato de decomposição para Q07 e viabilidade/suporte dos recortes de Q06; organização visual e seleção de medidas para o dashboard; desempenho de Power BI; licença do código antes de eventual publicação. Essas escolhas não permitem alterar P0, sinais ou denominadores aqui fechados. Se não houver suporte para uma comparação geográfica, apresentar a limitação e não forçar a resposta.

**Mudanças em relação ao planejamento inicial:** créditos deixam de ser pergunta de análise; participação e concentração distinguem comprador/cobrança; não há classificação exclusiva de produtos por Stock Group; análise de preço explicita a inconsistência da amostra; nenhuma meta ou corte subjetivo para alta/baixa performance é criado. A Etapa 2 é mantida como histórico de propostas; suas decisões pendentes são resolvidas aqui, sem reescrever o diagnóstico ou seu gerador.

## 12. Verificação cruzada da entrega

O contrato foi confrontado com `audit.json`, `followup.json`, `exceptions.json`, `pricing_semantics.json`, os três relatórios da Etapa 2 e o README atualizado. Os controles financeiros, contagens, datas e conjuntos especiais/negativos permanecem consistentes. A razão decimal dos valores auditados reproduz 49,7669% ao exibir quatro casas. A soma 301+211=512 e o subconjunto 4.626−512=4.114 são derivações dos controles existentes, não novas consultas comerciais.

O relatório antigo conserva o rótulo “proposta” por ser histórico; este contrato fornece a definição vigente. Não foram encontradas definições operacionais contraditórias entre os documentos. As especificações C01–C19 serão testadas no futuro modelo; nesta etapa foram verificadas apenas coerência documental, controles salvos, hashes e referências locais. LocalDB permaneceu parado.

**Arquivos desta entrega:** criado somente `reports/contrato_analitico_etapa3.md`; atualizado somente `README.md`. Dados, scripts e relatórios da Etapa 2 preservados. Etapa 4 aguarda autorização.
