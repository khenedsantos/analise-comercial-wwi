# Etapa 4 — evidência de validação

Execução SQL: `data/metadata/stage4-20260930-120408.json`; modo `Validate`.
**607 verificações aprovadas / 0 falhas / 607 executadas.**

Resultados abaixo derivam de execução, não da presença de código. A Etapa 4 só está validada quando não houver falhas.

| Contrato | Aprovadas | Falhas | Resultado |
| --- | ---: | ---: | --- |
| C01 | 15 | 0 | PASS |
| C02 | 15 | 0 | PASS |
| C03 | 7 | 0 | PASS |
| C04 | 119 | 0 | PASS |
| C05 | 2 | 0 | PASS |
| C06 | 33 | 0 | PASS |
| C07 | 86 | 0 | PASS |
| C08 | 62 | 0 | PASS |
| C09 | 1 | 0 | PASS |
| C10 | 57 | 0 | PASS |
| C11 | 7 | 0 | PASS |
| C12 | 4 | 0 | PASS |
| C13 | 57 | 0 | PASS |
| C14 | 86 | 0 | PASS |
| C15 | 6 | 0 | PASS |
| C16 | 25 | 0 | PASS |
| C17 | 5 | 0 | PASS |
| C18 | 7 | 0 | PASS |
| C19 | 13 | 0 | PASS |

## Controles financeiros

| Controle | Observado |
| --- | ---: |
| K01 | 172261341.2000000000 |
| K02 | 25782098.2500000000 |
| K03 | 198043439.4500000000 |
| K04 | 85729180.9000000000 |
| K05 | 49.7669298800 |

Somas monetárias confrontadas sem tolerância: centavos exatos. Margem recalculada; 49,7669% é apenas exibição. A divisão SQL tem precisão finita: testes Python usam Decimal de 50 dígitos e limite matemático de representação de 1e-8 ponto percentual (1e-10 UM para o ticket). Não se aplica essa tolerância às somas financeiras.

## Ambiente e preservação

- Espaço antes desta execução: 4.9623 GiB.
- Menor espaço registrado: 4.8366 GiB.
- Espaço após encerrar: 4.8366 GiB.
- Arquivos anteriores protegidos: 46; hashes inalterados: True.
- Código de parada LocalDB: 0.

```text
Nome: "WWI_Portfolio"

Vers�o:            17.0.1000.7

Nome compartilhado:        

Propriet�rio:              KHENED-SANTOS\khene

Cria��o autom�tica:       N�o

Estado:              Parado

�ltima hora de in�cio:    30/09/2026 12:04:09

Nome do pipe da inst�ncia:
```

## Cobertura e limites dos testes

- Comparação de conjuntos de IDs, PK/FK, versões históricas, fórmulas originais e sinais.
- Todos os 45 pares de Stock Groups: união e inclusão-exclusão para contagem de linhas e quatro somas financeiras. Sentinelas de join incorreto são calculadas sem materializar o join inflado.
- Cenários reais da API: eixos separados, seleções externas, membro visual, filtros simultâneos, grupos, recortes diagnósticos, vazio, domingos, limites, bissexto, acumulado, ano, MoM, parcial e descontínuo.
- Fixture de seis receitas empatadas apenas em memória de teste, sem inserção na WWI. Denominador zero e negativo testados na função usada pelas medidas.
- Campos de contexto e linhagem da saída verificados. Isso não valida apresentação no Power BI, ainda inexistente.
- Nenhuma nota de crédito foi fabricada/inserida na origem; C09 verifica a ausência real. A guarda de carga rejeita créditos novos, sem transformar seu sinal.
- A suite reconcilia o snapshot; não prova completude de uma empresa real nem causalidade.

## Retomada sem repetir testes SQL

Inspeção leve: `stage4-inspect-20261001-122009.json`. Todos os 565 asserts SQL anteriores foram reutilizados, inclusive os 45 pares. Conferência atual limitada ao catálogo, FKs e módulos; nenhuma carga ou restauração.
Espaço antes/depois da inspeção: 3.3847 / 3.5336 GiB. LocalDB encerrado normalmente.
Os números iniciais deste relatório referem-se à execução SQL de 30/09; a inspeção de retomada é separada. Módulos comparados normalizando somente o cabeçalho CREATE/CREATE OR ALTER e finais de linha. Três fixtures exercitam a função real do runner que aceita PASS e rejeita FAIL/ausência de asserts; não inserem dados no banco.

A primeira tentativa expirou antes da saída consolidada e não conta como aprovação. A segunda salvou 565 asserts PASS e 567 observações de KPIs (27 cenários × 21 medidas); observações não são contadas novamente como testes. Os 45 pares correspondem a duas asserções consolidadas, não a 45 linhas individuais de evidência.

## Verificações individuais

| Contrato | Verificação | Observado | Esperado | Status |
| --- | --- | --- | --- | --- |
| C01 | Additional fact IDs | 0.0000000000 | 0.0000000000 | PASS |
| C01 | Source IDs missing from fact | 0.0000000000 | 0.0000000000 | PASS |
| C02 | Distinct invoices | 70510.0000000000 | 70510.0000000000 | PASS |
| C02 | Distinct original IDs | 228265.0000000000 | 228265.0000000000 | PASS |
| C02 | Fact rows | 228265.0000000000 | 228265.0000000000 | PASS |
| C02 | Header consistency | 0.0000000000 | 0.0000000000 | PASS |
| C02 | Null grain | 0.0000000000 | 0.0000000000 | PASS |
| C02 | Source header and item keys (no OrderID-only item join) | 0.0000000000 | 0.0000000000 | PASS |
| C03 | Full dimensional joins preserve all lines | 228265.0000000000 | 228265.0000000000 | PASS |
| C03 | Missing temporal buyer versions | 0.0000000000 | 0.0000000000 | PASS |
| C03 | Missing temporal product versions | 0.0000000000 | 0.0000000000 | PASS |
| C03 | Temporal buyer cardinality | 70510.0000000000 | 70510.0000000000 | PASS |
| C03 | Temporal product cardinality | 228265.0000000000 | 228265.0000000000 | PASS |
| C03 | Untrusted or disabled FKs | 0.0000000000 | 0.0000000000 | PASS |
| C04 | annual_2014 K01 vs original source | 49929487.2000000000 | 49929487.2000000000 | PASS |
| C04 | annual_2014 K02 vs original source | 7489429.6900000000 | 7489429.6900000000 | PASS |
| C04 | annual_2014 K03 vs original source | 57418916.8900000000 | 57418916.8900000000 | PASS |
| C04 | annual_2014 K04 vs original source | 24828462.4500000000 | 24828462.4500000000 | PASS |
| C04 | billing_axis K01 vs original source | 172261341.2000000000 | 172261341.2000000000 | PASS |
| C04 | billing_axis K02 vs original source | 25782098.2500000000 | 25782098.2500000000 | PASS |
| C04 | billing_axis K03 vs original source | 198043439.4500000000 | 198043439.4500000000 | PASS |
| C04 | billing_axis K04 vs original source | 85729180.9000000000 | 85729180.9000000000 | PASS |
| C04 | buyer_bill_intersection K01 vs original source | 842098.3500000000 | 842098.3500000000 | PASS |
| C04 | buyer_bill_intersection K02 vs original source | 126183.0300000000 | 126183.0300000000 | PASS |
| C04 | buyer_bill_intersection K03 vs original source | 968281.3800000000 | 968281.3800000000 | PASS |
| C04 | buyer_bill_intersection K04 vs original source | 419575.6000000000 | 419575.6000000000 | PASS |
| C04 | category_city K01 vs original source | 305494.4000000000 | 305494.4000000000 | PASS |
| C04 | category_city K02 vs original source | 45803.6800000000 | 45803.6800000000 | PASS |
| C04 | category_city K03 vs original source | 351298.0800000000 | 351298.0800000000 | PASS |
| C04 | category_city K04 vs original source | 147225.1500000000 | 147225.1500000000 | PASS |
| C04 | discontinuous K01 vs original source | 232583.9500000000 | 232583.9500000000 | PASS |
| C04 | discontinuous K02 vs original source | 34427.4900000000 | 34427.4900000000 | PASS |
| C04 | discontinuous K03 vs original source | 267011.4400000000 | 267011.4400000000 | PASS |
| C04 | discontinuous K04 vs original source | 119456.9000000000 | 119456.9000000000 | PASS |
| C04 | empty_group K01 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C04 | empty_group K02 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C04 | empty_group K03 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C04 | empty_group K04 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C04 | first_mom K01 vs original source | 3770410.8500000000 | 3770410.8500000000 | PASS |
| C04 | first_mom K02 vs original source | 565562.1200000000 | 565562.1200000000 | PASS |
| C04 | first_mom K03 vs original source | 4335972.9700000000 | 4335972.9700000000 | PASS |
| C04 | first_mom K04 vs original source | 1890687.8000000000 | 1890687.8000000000 | PASS |
| C04 | first_yoy K01 vs original source | 45707188.0000000000 | 45707188.0000000000 | PASS |
| C04 | first_yoy K02 vs original source | 6856084.6400000000 | 6856084.6400000000 | PASS |
| C04 | first_yoy K03 vs original source | 52563272.6400000000 | 52563272.6400000000 | PASS |
| C04 | first_yoy K04 vs original source | 22768352.2500000000 | 22768352.2500000000 | PASS |
| C04 | Gross sales exact cents | 198043439.4500000000 | 198043439.4500000000 | PASS |
| C04 | group_product_intersection K01 vs original source | 287866.2500000000 | 287866.2500000000 | PASS |
| C04 | group_product_intersection K02 vs original source | 43180.0900000000 | 43180.0900000000 | PASS |
| C04 | group_product_intersection K03 vs original source | 331046.3400000000 | 331046.3400000000 | PASS |
| C04 | group_product_intersection K04 vs original source | 174654.7500000000 | 174654.7500000000 | PASS |
| C04 | group_union K01 vs original source | 4724985.4500000000 | 4724985.4500000000 | PASS |
| C04 | group_union K02 vs original source | 708747.9700000000 | 708747.9700000000 | PASS |
| C04 | group_union K03 vs original source | 5433733.4200000000 | 5433733.4200000000 | PASS |
| C04 | group_union K04 vs original source | 2908387.4500000000 | 2908387.4500000000 | PASS |
| C04 | Invoice financial identities | 0.0000000000 | 0.0000000000 | PASS |
| C04 | K01 API | 172261341.2000000000 | 172261341.2000000000 | PASS |
| C04 | K02 API | 25782098.2500000000 | 25782098.2500000000 | PASS |
| C04 | K03 API | 198043439.4500000000 | 198043439.4500000000 | PASS |
| C04 | K04 API | 85729180.9000000000 | 85729180.9000000000 | PASS |
| C04 | leap_yoy K01 vs original source | 4005616.8500000000 | 4005616.8500000000 | PASS |
| C04 | leap_yoy K02 vs original source | 590917.9300000000 | 590917.9300000000 | PASS |
| C04 | leap_yoy K03 vs original source | 4596534.7800000000 | 4596534.7800000000 | PASS |
| C04 | leap_yoy K04 vs original source | 1975672.4500000000 | 1975672.4500000000 | PASS |
| C04 | mom K01 vs original source | 4480730.5500000000 | 4480730.5500000000 | PASS |
| C04 | mom K02 vs original source | 672110.1700000000 | 672110.1700000000 | PASS |
| C04 | mom K03 vs original source | 5152840.7200000000 | 5152840.7200000000 | PASS |
| C04 | mom K04 vs original source | 2220597.6500000000 | 2220597.6500000000 | PASS |
| C04 | Month financial identities | 0.0000000000 | 0.0000000000 | PASS |
| C04 | negative_only K01 vs original source | 4962959.4500000000 | 4962959.4500000000 | PASS |
| C04 | negative_only K02 vs original source | 744444.0700000000 | 744444.0700000000 | PASS |
| C04 | negative_only K03 vs original source | 5707403.5200000000 | 5707403.5200000000 | PASS |
| C04 | negative_only K04 vs original source | -320493.5500000000 | -320493.5500000000 | PASS |
| C04 | Net sales exact cents | 172261341.2000000000 | 172261341.2000000000 | PASS |
| C04 | no_group_selection K01 vs original source | 22633175.5500000000 | 22633175.5500000000 | PASS |
| C04 | no_group_selection K02 vs original source | 3337853.5600000000 | 3337853.5600000000 | PASS |
| C04 | no_group_selection K03 vs original source | 25971029.1100000000 | 25971029.1100000000 | PASS |
| C04 | no_group_selection K04 vs original source | 11174765.5500000000 | 11174765.5500000000 | PASS |
| C04 | non_special_positive K01 vs original source | 22020672.1000000000 | 22020672.1000000000 | PASS |
| C04 | non_special_positive K02 vs original source | 3245977.8900000000 | 3245977.8900000000 | PASS |
| C04 | non_special_positive K03 vs original source | 25266649.9900000000 | 25266649.9900000000 | PASS |
| C04 | non_special_positive K04 vs original source | 11253567.1000000000 | 11253567.1000000000 | PASS |
| C04 | null_buying_group K01 vs original source | 63528695.7000000000 | 63528695.7000000000 | PASS |
| C04 | null_buying_group K02 vs original source | 9508348.0800000000 | 9508348.0800000000 | PASS |
| C04 | null_buying_group K03 vs original source | 73037043.7800000000 | 73037043.7800000000 | PASS |
| C04 | null_buying_group K04 vs original source | 31660852.7500000000 | 31660852.7500000000 | PASS |
| C04 | outside K01 vs original source | None | None | PASS |
| C04 | outside K02 vs original source | None | None | PASS |
| C04 | outside K03 vs original source | None | None | PASS |
| C04 | outside K04 vs original source | None | None | PASS |
| C04 | partial_basket K01 vs original source | 141342.5000000000 | 141342.5000000000 | PASS |
| C04 | partial_basket K02 vs original source | 21201.4500000000 | 21201.4500000000 | PASS |
| C04 | partial_basket K03 vs original source | 162543.9500000000 | 162543.9500000000 | PASS |
| C04 | partial_basket K04 vs original source | 85587.0000000000 | 85587.0000000000 | PASS |
| C04 | partial_month K01 vs original source | 4970932.6500000000 | 4970932.6500000000 | PASS |
| C04 | partial_month K02 vs original source | 733300.0600000000 | 733300.0600000000 | PASS |
| C04 | partial_month K03 vs original source | 5704232.7100000000 | 5704232.7100000000 | PASS |
| C04 | partial_month K04 vs original source | 2443448.5500000000 | 2443448.5500000000 | PASS |
| C04 | Product financial identities | 0.0000000000 | 0.0000000000 | PASS |
| C04 | product_axis K01 vs original source | 172261341.2000000000 | 172261341.2000000000 | PASS |
| C04 | product_axis K02 vs original source | 25782098.2500000000 | 25782098.2500000000 | PASS |
| C04 | product_axis K03 vs original source | 198043439.4500000000 | 198043439.4500000000 | PASS |
| C04 | product_axis K04 vs original source | 85729180.9000000000 | 85729180.9000000000 | PASS |
| C04 | Recorded profit exact cents | 85729180.9000000000 | 85729180.9000000000 | PASS |
| C04 | selected_buyers K01 vs original source | 305494.4000000000 | 305494.4000000000 | PASS |
| C04 | selected_buyers K02 vs original source | 45803.6800000000 | 45803.6800000000 | PASS |
| C04 | selected_buyers K03 vs original source | 351298.0800000000 | 351298.0800000000 | PASS |
| C04 | selected_buyers K04 vs original source | 147225.1500000000 | 147225.1500000000 | PASS |
| C04 | selected_products K01 vs original source | 141342.5000000000 | 141342.5000000000 | PASS |
| C04 | selected_products K02 vs original source | 21201.4500000000 | 21201.4500000000 | PASS |
| C04 | selected_products K03 vs original source | 162543.9500000000 | 162543.9500000000 | PASS |
| C04 | selected_products K04 vs original source | 85587.0000000000 | 85587.0000000000 | PASS |
| C04 | special_only K01 vs original source | 21959.4500000000 | 21959.4500000000 | PASS |
| C04 | special_only K02 vs original source | 3294.0700000000 | 3294.0700000000 | PASS |
| C04 | special_only K03 vs original source | 25253.5200000000 | 25253.5200000000 | PASS |
| C04 | special_only K04 vs original source | -45993.5500000000 | -45993.5500000000 | PASS |
| C04 | sunday K01 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C04 | sunday K02 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C04 | sunday K03 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C04 | sunday K04 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C04 | Tax exact cents | 25782098.2500000000 | 25782098.2500000000 | PASS |
| C04 | ytd_2016 K01 vs original source | 22633175.5500000000 | 22633175.5500000000 | PASS |
| C04 | ytd_2016 K02 vs original source | 3337853.5600000000 | 3337853.5600000000 | PASS |
| C04 | ytd_2016 K03 vs original source | 25971029.1100000000 | 25971029.1100000000 | PASS |
| C04 | ytd_2016 K04 vs original source | 11174765.5500000000 | 11174765.5500000000 | PASS |
| C04 | zero_base K01 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C04 | zero_base K02 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C04 | zero_base K03 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C04 | zero_base K04 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C05 | All original financial fields and source formulas | 0.0000000000 | 0.0000000000 | PASS |
| C05 | Snapshot cost reference only; no replacement | 0.0000000000 | 0.0000000000 | PASS |
| C06 | annual_2014 K05 vs original source | 49.7270527700 | 49.7270527700 | PASS |
| C06 | billing_axis K05 vs original source | 49.7669298800 | 49.7669298800 | PASS |
| C06 | buyer_bill_intersection K05 vs original source | 49.8250115300 | 49.8250115300 | PASS |
| C06 | category_city K05 vs original source | 48.1924218500 | 48.1924218500 | PASS |
| C06 | discontinuous K05 vs original source | 51.3607667200 | 51.3607667200 | PASS |
| C06 | empty_group K05 vs original source | None | None | PASS |
| C06 | first_mom K05 vs original source | 50.1454052400 | 50.1454052400 | PASS |
| C06 | first_yoy K05 vs original source | 49.8135047100 | 49.8135047100 | PASS |
| C06 | group_product_intersection K05 vs original source | 60.6721871700 | 60.6721871700 | PASS |
| C06 | group_union K05 vs original source | 61.5533630900 | 61.5533630900 | PASS |
| C06 | K05 display | 49.7669000000 | 49.7669000000 | PASS |
| C06 | K05 ratio before display | 49.7669298800 | 49.7669298800 | PASS |
| C06 | leap_yoy K05 vs original source | 49.3225519000 | 49.3225519000 | PASS |
| C06 | mom K05 vs original source | 49.5588303100 | 49.5588303100 | PASS |
| C06 | Negative denominator helper | None | None | PASS |
| C06 | negative_only K05 vs original source | -6.4577104200 | -6.4577104200 | PASS |
| C06 | no_group_selection K05 vs original source | 49.3733878600 | 49.3733878600 | PASS |
| C06 | non_special_positive K05 vs original source | 51.1045577900 | 51.1045577900 | PASS |
| C06 | null_buying_group K05 vs original source | 49.8370892100 | 49.8370892100 | PASS |
| C06 | outside K05 vs original source | None | None | PASS |
| C06 | partial_basket K05 vs original source | 60.5529122500 | 60.5529122500 | PASS |
| C06 | partial_month K05 vs original source | 49.1547305500 | 49.1547305500 | PASS |
| C06 | product_axis K05 vs original source | 49.7669298800 | 49.7669298800 | PASS |
| C06 | selected_buyers K05 vs original source | 48.1924218500 | 48.1924218500 | PASS |
| C06 | selected_products K05 vs original source | 60.5529122500 | 60.5529122500 | PASS |
| C06 | special_only K05 vs original source | -209.4476409900 | -209.4476409900 | PASS |
| C06 | sunday K05 vs original source | None | None | PASS |
| C06 | Unweighted mean differs from required margin | 1.0000000000 | 1.0000000000 | PASS |
| C06 | ytd_2016 K05 vs original source | 49.3733878600 | 49.3733878600 | PASS |
| C06 | Zero denominator helper | None | None | PASS |
| C06 | zero_base K05 vs original source | None | None | PASS |
| C07 | annual_2014 K17 vs original source | 1215.0000000000 | 1215.0000000000 | PASS |
| C07 | annual_2014 K18 vs original source | 1.8425562200 | 1.8425562200 | PASS |
| C07 | annual_2014 K19 vs original source | -81696.0000000000 | -81696.0000000000 | PASS |
| C07 | billing_axis K17 vs original source | 4626.0000000000 | 4626.0000000000 | PASS |
| C07 | billing_axis K18 vs original source | 2.0265918900 | 2.0265918900 | PASS |
| C07 | billing_axis K19 vs original source | -320493.5500000000 | -320493.5500000000 | PASS |
| C07 | buyer_bill_intersection K17 vs original source | 26.0000000000 | 26.0000000000 | PASS |
| C07 | buyer_bill_intersection K18 vs original source | 2.1594684300 | 2.1594684300 | PASS |
| C07 | buyer_bill_intersection K19 vs original source | -1752.0000000000 | -1752.0000000000 | PASS |
| C07 | category_city K17 vs original source | 10.0000000000 | 10.0000000000 | PASS |
| C07 | category_city K18 vs original source | 2.4630541800 | 2.4630541800 | PASS |
| C07 | category_city K19 vs original source | -708.0000000000 | -708.0000000000 | PASS |
| C07 | discontinuous K17 vs original source | 8.0000000000 | 8.0000000000 | PASS |
| C07 | discontinuous K18 vs original source | 2.8169014000 | 2.8169014000 | PASS |
| C07 | discontinuous K19 vs original source | -312.0000000000 | -312.0000000000 | PASS |
| C07 | empty_group K17 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C07 | empty_group K18 vs original source | None | None | PASS |
| C07 | empty_group K19 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C07 | Explicit negative-only denominator retained | 100.0000000000 | 100.0000000000 | PASS |
| C07 | first_mom K17 vs original source | 88.0000000000 | 88.0000000000 | PASS |
| C07 | first_mom K18 vs original source | 1.6774685400 | 1.6774685400 | PASS |
| C07 | first_mom K19 vs original source | -5604.0000000000 | -5604.0000000000 | PASS |
| C07 | first_yoy K17 vs original source | 1088.0000000000 | 1088.0000000000 | PASS |
| C07 | first_yoy K18 vs original source | 1.7845427100 | 1.7845427100 | PASS |
| C07 | first_yoy K19 vs original source | -72360.0000000000 | -72360.0000000000 | PASS |
| C07 | group_product_intersection K17 vs original source | 75.0000000000 | 75.0000000000 | PASS |
| C07 | group_product_intersection K18 vs original source | 3.5277516400 | 3.5277516400 | PASS |
| C07 | group_product_intersection K19 vs original source | -2944.2500000000 | -2944.2500000000 | PASS |
| C07 | group_union K17 vs original source | 512.0000000000 | 512.0000000000 | PASS |
| C07 | group_union K18 vs original source | 3.4515302600 | 3.4515302600 | PASS |
| C07 | group_union K19 vs original source | -45993.5500000000 | -45993.5500000000 | PASS |
| C07 | K17 | 4626.0000000000 | 4626.0000000000 | PASS |
| C07 | K18 exact API precision | 2.0265918900 | 2.0265918900 | PASS |
| C07 | K19 signed | -320493.5500000000 | -320493.5500000000 | PASS |
| C07 | leap_yoy K17 vs original source | 203.0000000000 | 203.0000000000 | PASS |
| C07 | leap_yoy K18 vs original source | 3.9068514200 | 3.9068514200 | PASS |
| C07 | leap_yoy K19 vs original source | -18121.2000000000 | -18121.2000000000 | PASS |
| C07 | mom K17 vs original source | 103.0000000000 | 103.0000000000 | PASS |
| C07 | mom K18 vs original source | 1.7166666600 | 1.7166666600 | PASS |
| C07 | mom K19 vs original source | -7092.0000000000 | -7092.0000000000 | PASS |
| C07 | Negative flag equivalence | 0.0000000000 | 0.0000000000 | PASS |
| C07 | Negative lines | 4626.0000000000 | 4626.0000000000 | PASS |
| C07 | negative_only K17 vs original source | 4626.0000000000 | 4626.0000000000 | PASS |
| C07 | negative_only K18 vs original source | 100.0000000000 | 100.0000000000 | PASS |
| C07 | negative_only K19 vs original source | -320493.5500000000 | -320493.5500000000 | PASS |
| C07 | no_group_selection K17 vs original source | 1021.0000000000 | 1021.0000000000 | PASS |
| C07 | no_group_selection K18 vs original source | 3.4659515200 | 3.4659515200 | PASS |
| C07 | no_group_selection K19 vs original source | -78801.5500000000 | -78801.5500000000 | PASS |
| C07 | non_special_positive K17 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C07 | non_special_positive K18 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C07 | non_special_positive K19 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C07 | null_buying_group K17 vs original source | 1512.0000000000 | 1512.0000000000 | PASS |
| C07 | null_buying_group K18 vs original source | 1.7936581300 | 1.7936581300 | PASS |
| C07 | null_buying_group K19 vs original source | -98652.0000000000 | -98652.0000000000 | PASS |
| C07 | outside K17 vs original source | None | None | PASS |
| C07 | outside K18 vs original source | None | None | PASS |
| C07 | outside K19 vs original source | None | None | PASS |
| C07 | partial_basket K17 vs original source | 40.0000000000 | 40.0000000000 | PASS |
| C07 | partial_basket K18 vs original source | 3.8167938900 | 3.8167938900 | PASS |
| C07 | partial_basket K19 vs original source | -1554.0000000000 | -1554.0000000000 | PASS |
| C07 | partial_month K17 vs original source | 206.0000000000 | 206.0000000000 | PASS |
| C07 | partial_month K18 vs original source | 3.2435836800 | 3.2435836800 | PASS |
| C07 | partial_month K19 vs original source | -12968.0500000000 | -12968.0500000000 | PASS |
| C07 | product_axis K17 vs original source | 4626.0000000000 | 4626.0000000000 | PASS |
| C07 | product_axis K18 vs original source | 2.0265918900 | 2.0265918900 | PASS |
| C07 | product_axis K19 vs original source | -320493.5500000000 | -320493.5500000000 | PASS |
| C07 | selected_buyers K17 vs original source | 10.0000000000 | 10.0000000000 | PASS |
| C07 | selected_buyers K18 vs original source | 2.4630541800 | 2.4630541800 | PASS |
| C07 | selected_buyers K19 vs original source | -708.0000000000 | -708.0000000000 | PASS |
| C07 | selected_products K17 vs original source | 40.0000000000 | 40.0000000000 | PASS |
| C07 | selected_products K18 vs original source | 3.8167938900 | 3.8167938900 | PASS |
| C07 | selected_products K19 vs original source | -1554.0000000000 | -1554.0000000000 | PASS |
| C07 | Signed negative profit | -320493.5500000000 | -320493.5500000000 | PASS |
| C07 | special_only K17 vs original source | 512.0000000000 | 512.0000000000 | PASS |
| C07 | special_only K18 vs original source | 100.0000000000 | 100.0000000000 | PASS |
| C07 | special_only K19 vs original source | -45993.5500000000 | -45993.5500000000 | PASS |
| C07 | sunday K17 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C07 | sunday K18 vs original source | None | None | PASS |
| C07 | sunday K19 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C07 | ytd_2016 K17 vs original source | 1021.0000000000 | 1021.0000000000 | PASS |
| C07 | ytd_2016 K18 vs original source | 3.4659515200 | 3.4659515200 | PASS |
| C07 | ytd_2016 K19 vs original source | -78801.5500000000 | -78801.5500000000 | PASS |
| C07 | zero_base K17 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C07 | zero_base K18 vs original source | None | None | PASS |
| C07 | zero_base K19 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C08 | Agreement 1 | 301.0000000000 | 301.0000000000 | PASS |
| C08 | Agreement 2 | 211.0000000000 | 211.0000000000 | PASS |
| C08 | annual_2014 K20 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C08 | annual_2014 K21 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C08 | billing_axis K20 vs original source | 512.0000000000 | 512.0000000000 | PASS |
| C08 | billing_axis K21 vs original source | 0.0127477500 | 0.0127477500 | PASS |
| C08 | buyer_bill_intersection K20 vs original source | 1.0000000000 | 1.0000000000 | PASS |
| C08 | buyer_bill_intersection K21 vs original source | 0.0028500200 | 0.0028500200 | PASS |
| C08 | category_city K20 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C08 | category_city K21 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C08 | discontinuous K20 vs original source | 5.0000000000 | 5.0000000000 | PASS |
| C08 | discontinuous K21 vs original source | 0.0412754100 | 0.0412754100 | PASS |
| C08 | empty_group K20 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C08 | empty_group K21 vs original source | None | None | PASS |
| C08 | Expected special association missing | 0.0000000000 | 0.0000000000 | PASS |
| C08 | Explicit special-only denominator retained | 100.0000000000 | 100.0000000000 | PASS |
| C08 | first_mom K20 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C08 | first_mom K21 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C08 | first_yoy K20 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C08 | first_yoy K21 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C08 | group_product_intersection K20 vs original source | 75.0000000000 | 75.0000000000 | PASS |
| C08 | group_product_intersection K21 vs original source | 0.4919819500 | 0.4919819500 | PASS |
| C08 | group_union K20 vs original source | 512.0000000000 | 512.0000000000 | PASS |
| C08 | group_union K21 vs original source | 0.4647516900 | 0.4647516900 | PASS |
| C08 | Independent historical eligibility count | 512.0000000000 | 512.0000000000 | PASS |
| C08 | K20 | 512.0000000000 | 512.0000000000 | PASS |
| C08 | K21 special revenue denominator | 0.0127477500 | 0.0127477500 | PASS |
| C08 | leap_yoy K20 vs original source | 103.0000000000 | 103.0000000000 | PASS |
| C08 | leap_yoy K21 vs original source | 0.1080058300 | 0.1080058300 | PASS |
| C08 | mom K20 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C08 | mom K21 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C08 | Negative non-special | 4114.0000000000 | 4114.0000000000 | PASS |
| C08 | negative_only K20 vs original source | 512.0000000000 | 512.0000000000 | PASS |
| C08 | negative_only K21 vs original source | 0.4424668400 | 0.4424668400 | PASS |
| C08 | no_group_selection K20 vs original source | 512.0000000000 | 512.0000000000 | PASS |
| C08 | no_group_selection K21 vs original source | 0.0970232800 | 0.0970232800 | PASS |
| C08 | non_special_positive K20 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C08 | non_special_positive K21 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C08 | null_buying_group K20 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C08 | null_buying_group K21 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C08 | outside K20 vs original source | None | None | PASS |
| C08 | outside K21 vs original source | None | None | PASS |
| C08 | partial_basket K20 vs original source | 40.0000000000 | 40.0000000000 | PASS |
| C08 | partial_basket K21 vs original source | 0.5606947600 | 0.5606947600 | PASS |
| C08 | partial_month K20 vs original source | 108.0000000000 | 108.0000000000 | PASS |
| C08 | partial_month K21 vs original source | 0.0864012900 | 0.0864012900 | PASS |
| C08 | product_axis K20 vs original source | 512.0000000000 | 512.0000000000 | PASS |
| C08 | product_axis K21 vs original source | 0.0127477500 | 0.0127477500 | PASS |
| C08 | selected_buyers K20 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C08 | selected_buyers K21 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C08 | selected_products K20 vs original source | 40.0000000000 | 40.0000000000 | PASS |
| C08 | selected_products K21 vs original source | 0.5606947600 | 0.5606947600 | PASS |
| C08 | Special outside negative set | 0.0000000000 | 0.0000000000 | PASS |
| C08 | special_only K20 vs original source | 512.0000000000 | 512.0000000000 | PASS |
| C08 | special_only K21 vs original source | 100.0000000000 | 100.0000000000 | PASS |
| C08 | sunday K20 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C08 | sunday K21 vs original source | None | None | PASS |
| C08 | Unexpected special association | 0.0000000000 | 0.0000000000 | PASS |
| C08 | ytd_2016 K20 vs original source | 512.0000000000 | 512.0000000000 | PASS |
| C08 | ytd_2016 K21 vs original source | 0.0970232800 | 0.0970232800 | PASS |
| C08 | zero_base K20 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C08 | zero_base K21 vs original source | None | None | PASS |
| C09 | Observed credits | 0.0000000000 | 0.0000000000 | PASS |
| C10 | annual_2014 K07 vs original source | 640.0000000000 | 640.0000000000 | PASS |
| C10 | annual_2014 K08 vs original source | 240.0000000000 | 240.0000000000 | PASS |
| C10 | Billing dimension | 263.0000000000 | 263.0000000000 | PASS |
| C10 | billing_axis K07 vs original source | 663.0000000000 | 663.0000000000 | PASS |
| C10 | billing_axis K08 vs original source | 263.0000000000 | 263.0000000000 | PASS |
| C10 | Buyer dimension | 663.0000000000 | 663.0000000000 | PASS |
| C10 | buyer_bill_intersection K07 vs original source | 3.0000000000 | 3.0000000000 | PASS |
| C10 | buyer_bill_intersection K08 vs original source | 1.0000000000 | 1.0000000000 | PASS |
| C10 | category_city K07 vs original source | 1.0000000000 | 1.0000000000 | PASS |
| C10 | category_city K08 vs original source | 1.0000000000 | 1.0000000000 | PASS |
| C10 | discontinuous K07 vs original source | 76.0000000000 | 76.0000000000 | PASS |
| C10 | discontinuous K08 vs original source | 39.0000000000 | 39.0000000000 | PASS |
| C10 | empty_group K07 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C10 | empty_group K08 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C10 | first_mom K07 vs original source | 546.0000000000 | 546.0000000000 | PASS |
| C10 | first_mom K08 vs original source | 182.0000000000 | 182.0000000000 | PASS |
| C10 | first_yoy K07 vs original source | 625.0000000000 | 625.0000000000 | PASS |
| C10 | first_yoy K08 vs original source | 225.0000000000 | 225.0000000000 | PASS |
| C10 | group_product_intersection K07 vs original source | 636.0000000000 | 636.0000000000 | PASS |
| C10 | group_product_intersection K08 vs original source | 243.0000000000 | 243.0000000000 | PASS |
| C10 | group_union K07 vs original source | 662.0000000000 | 662.0000000000 | PASS |
| C10 | group_union K08 vs original source | 262.0000000000 | 262.0000000000 | PASS |
| C10 | Invoice customer roles preserved | 0.0000000000 | 0.0000000000 | PASS |
| C10 | K07 buyers | 663.0000000000 | 663.0000000000 | PASS |
| C10 | K08 billing | 263.0000000000 | 263.0000000000 | PASS |
| C10 | leap_yoy K07 vs original source | 598.0000000000 | 598.0000000000 | PASS |
| C10 | leap_yoy K08 vs original source | 230.0000000000 | 230.0000000000 | PASS |
| C10 | mom K07 vs original source | 605.0000000000 | 605.0000000000 | PASS |
| C10 | mom K08 vs original source | 232.0000000000 | 232.0000000000 | PASS |
| C10 | negative_only K07 vs original source | 653.0000000000 | 653.0000000000 | PASS |
| C10 | negative_only K08 vs original source | 253.0000000000 | 253.0000000000 | PASS |
| C10 | no_group_selection K07 vs original source | 663.0000000000 | 663.0000000000 | PASS |
| C10 | no_group_selection K08 vs original source | 263.0000000000 | 263.0000000000 | PASS |
| C10 | non_special_positive K07 vs original source | 663.0000000000 | 663.0000000000 | PASS |
| C10 | non_special_positive K08 vs original source | 263.0000000000 | 263.0000000000 | PASS |
| C10 | null_buying_group K07 vs original source | 261.0000000000 | 261.0000000000 | PASS |
| C10 | null_buying_group K08 vs original source | 261.0000000000 | 261.0000000000 | PASS |
| C10 | outside K07 vs original source | None | None | PASS |
| C10 | outside K08 vs original source | None | None | PASS |
| C10 | partial_basket K07 vs original source | 514.0000000000 | 514.0000000000 | PASS |
| C10 | partial_basket K08 vs original source | 201.0000000000 | 201.0000000000 | PASS |
| C10 | partial_month K07 vs original source | 629.0000000000 | 629.0000000000 | PASS |
| C10 | partial_month K08 vs original source | 247.0000000000 | 247.0000000000 | PASS |
| C10 | product_axis K07 vs original source | 663.0000000000 | 663.0000000000 | PASS |
| C10 | product_axis K08 vs original source | 263.0000000000 | 263.0000000000 | PASS |
| C10 | selected_buyers K07 vs original source | 1.0000000000 | 1.0000000000 | PASS |
| C10 | selected_buyers K08 vs original source | 1.0000000000 | 1.0000000000 | PASS |
| C10 | selected_products K07 vs original source | 514.0000000000 | 514.0000000000 | PASS |
| C10 | selected_products K08 vs original source | 201.0000000000 | 201.0000000000 | PASS |
| C10 | special_only K07 vs original source | 281.0000000000 | 281.0000000000 | PASS |
| C10 | special_only K08 vs original source | 2.0000000000 | 2.0000000000 | PASS |
| C10 | sunday K07 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C10 | sunday K08 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C10 | ytd_2016 K07 vs original source | 663.0000000000 | 663.0000000000 | PASS |
| C10 | ytd_2016 K08 vs original source | 263.0000000000 | 263.0000000000 | PASS |
| C10 | zero_base K07 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C10 | zero_base K08 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C11 | All groups union restores P0 | 228265.0000000000 | 228265.0000000000 | PASS |
| C11 | Bridge pairs | 442.0000000000 | 442.0000000000 | PASS |
| C11 | One group | 94.0000000000 | 94.0000000000 | PASS |
| C11 | Products | 227.0000000000 | 227.0000000000 | PASS |
| C11 | Three groups | 82.0000000000 | 82.0000000000 | PASS |
| C11 | Two groups | 51.0000000000 | 51.0000000000 | PASS |
| C11 | Ungrouped products | 0.0000000000 | 0.0000000000 | PASS |
| C12 | Deliberately wrong join revenue sentinel detected | 275964455.1000000000 | 275964455.1000000000 | PASS |
| C12 | Deliberately wrong join row sentinel detected | 450703.0000000000 | 450703.0000000000 | PASS |
| C12 | Exhaustive pairs executed | 45.0000000000 | 45.0000000000 | PASS |
| C12 | Union and inclusion-exclusion mismatches (count and four sums) | 0.0000000000 | 0.0000000000 | PASS |
| C13 | annual_2014 K11 vs original source | 100.0000000000 | 100.0000000000 | PASS |
| C13 | annual_2014 K12 source ranking | 1.4138513900 | 1.4138513900 | PASS |
| C13 | billing_axis K11 vs original source | 100.0000000000 | 100.0000000000 | PASS |
| C13 | billing_axis K12 source ranking | 63.7540043700 | 63.7540043700 | PASS |
| C13 | buyer_bill_intersection K11 vs original source | 100.0000000000 | 100.0000000000 | PASS |
| C13 | buyer_bill_intersection K12 source ranking | 100.0000000000 | 100.0000000000 | PASS |
| C13 | category_city K11 vs original source | 100.0000000000 | 100.0000000000 | PASS |
| C13 | category_city K12 source ranking | None | None | PASS |
| C13 | discontinuous K11 vs original source | 100.0000000000 | 100.0000000000 | PASS |
| C13 | discontinuous K12 source ranking | 27.6991598000 | 27.6991598000 | PASS |
| C13 | empty_group K11 vs original source | None | None | PASS |
| C13 | empty_group K12 source ranking | None | None | PASS |
| C13 | Fewer than five selected products | 100.0000000000 | 100.0000000000 | PASS |
| C13 | first_mom K11 vs original source | 100.0000000000 | 100.0000000000 | PASS |
| C13 | first_mom K12 source ranking | 4.0517202500 | 4.0517202500 | PASS |
| C13 | first_yoy K11 vs original source | 100.0000000000 | 100.0000000000 | PASS |
| C13 | first_yoy K12 source ranking | 1.5483934300 | 1.5483934300 | PASS |
| C13 | group_product_intersection K11 vs original source | 100.0000000000 | 100.0000000000 | PASS |
| C13 | group_product_intersection K12 source ranking | 100.0000000000 | 100.0000000000 | PASS |
| C13 | group_union K11 vs original source | 47.9232847100 | 47.9232847100 | PASS |
| C13 | group_union K12 source ranking | None | None | PASS |
| C13 | leap_yoy K11 vs original source | 100.0000000000 | 100.0000000000 | PASS |
| C13 | leap_yoy K12 source ranking | 4.3156823600 | 4.3156823600 | PASS |
| C13 | mom K11 vs original source | 100.0000000000 | 100.0000000000 | PASS |
| C13 | mom K12 source ranking | 3.7842545500 | 3.7842545500 | PASS |
| C13 | negative_only K11 vs original source | 100.0000000000 | 100.0000000000 | PASS |
| C13 | negative_only K12 source ranking | 1.8876610000 | 1.8876610000 | PASS |
| C13 | no_group_selection K11 vs original source | 100.0000000000 | 100.0000000000 | PASS |
| C13 | no_group_selection K12 source ranking | 1.8583980800 | 1.8583980800 | PASS |
| C13 | non_special_positive K11 vs original source | 100.0000000000 | 100.0000000000 | PASS |
| C13 | non_special_positive K12 source ranking | 1.8876621800 | 1.8876621800 | PASS |
| C13 | null_buying_group K11 vs original source | 100.0000000000 | 100.0000000000 | PASS |
| C13 | null_buying_group K12 source ranking | 2.8318501200 | 2.8318501200 | PASS |
| C13 | outside K11 vs original source | None | None | PASS |
| C13 | outside K12 source ranking | None | None | PASS |
| C13 | partial_basket K11 vs original source | 100.0000000000 | 100.0000000000 | PASS |
| C13 | partial_basket K12 source ranking | 100.0000000000 | 100.0000000000 | PASS |
| C13 | partial_month K11 vs original source | 100.0000000000 | 100.0000000000 | PASS |
| C13 | partial_month K12 source ranking | 3.8297803100 | 3.8297803100 | PASS |
| C13 | product_axis K11 vs original source | 100.0000000000 | 100.0000000000 | PASS |
| C13 | product_axis K12 source ranking | 21.0290252800 | 21.0290252800 | PASS |
| C13 | Reject malformed ID selection | 1.0000000000 | 1.0000000000 | PASS |
| C13 | Reject unknown axis | 1.0000000000 | 1.0000000000 | PASS |
| C13 | Reject unknown filter | 1.0000000000 | 1.0000000000 | PASS |
| C13 | selected_buyers K11 vs original source | 13.8164543700 | 13.8164543700 | PASS |
| C13 | selected_buyers K12 source ranking | 67.5968717900 | 67.5968717900 | PASS |
| C13 | selected_products K11 vs original source | 7.6210772900 | 7.6210772900 | PASS |
| C13 | selected_products K12 source ranking | 92.3789227000 | 92.3789227000 | PASS |
| C13 | special_only K11 vs original source | 100.0000000000 | 100.0000000000 | PASS |
| C13 | special_only K12 source ranking | 9.7051611000 | 9.7051611000 | PASS |
| C13 | sunday K11 vs original source | None | None | PASS |
| C13 | sunday K12 source ranking | None | None | PASS |
| C13 | TEST FIXTURE deterministic five-way tie boundary | 15.0000000000 | 15.0000000000 | PASS |
| C13 | ytd_2016 K11 vs original source | 100.0000000000 | 100.0000000000 | PASS |
| C13 | ytd_2016 K12 source ranking | 1.8583980800 | 1.8583980800 | PASS |
| C13 | zero_base K11 vs original source | None | None | PASS |
| C13 | zero_base K12 source ranking | None | None | PASS |
| C14 | annual_2014 K06 vs original source | 20303.0000000000 | 20303.0000000000 | PASS |
| C14 | annual_2014 K09 vs original source | 219.0000000000 | 219.0000000000 | PASS |
| C14 | annual_2014 K10 vs original source | 2459.2172191301 | 2459.2172191301 | PASS |
| C14 | billing_axis K06 vs original source | 70510.0000000000 | 70510.0000000000 | PASS |
| C14 | billing_axis K09 vs original source | 227.0000000000 | 227.0000000000 | PASS |
| C14 | billing_axis K10 vs original source | 2443.0767437242 | 2443.0767437242 | PASS |
| C14 | Buyer distinct counts not additive across products | 1.0000000000 | 1.0000000000 | PASS |
| C14 | buyer_bill_intersection K06 vs original source | 365.0000000000 | 365.0000000000 | PASS |
| C14 | buyer_bill_intersection K09 vs original source | 221.0000000000 | 221.0000000000 | PASS |
| C14 | buyer_bill_intersection K10 vs original source | 2307.1187671232 | 2307.1187671232 | PASS |
| C14 | category_city K06 vs original source | 123.0000000000 | 123.0000000000 | PASS |
| C14 | category_city K09 vs original source | 189.0000000000 | 189.0000000000 | PASS |
| C14 | category_city K10 vs original source | 2483.6943089430 | 2483.6943089430 | PASS |
| C14 | discontinuous K06 vs original source | 84.0000000000 | 84.0000000000 | PASS |
| C14 | discontinuous K09 vs original source | 164.0000000000 | 164.0000000000 | PASS |
| C14 | discontinuous K10 vs original source | 2768.8565476190 | 2768.8565476190 | PASS |
| C14 | empty_group K06 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C14 | empty_group K09 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C14 | empty_group K10 vs original source | None | None | PASS |
| C14 | first_mom K06 vs original source | 1639.0000000000 | 1639.0000000000 | PASS |
| C14 | first_mom K09 vs original source | 219.0000000000 | 219.0000000000 | PASS |
| C14 | first_mom K10 vs original source | 2300.4337095790 | 2300.4337095790 | PASS |
| C14 | first_yoy K06 vs original source | 18767.0000000000 | 18767.0000000000 | PASS |
| C14 | first_yoy K09 vs original source | 219.0000000000 | 219.0000000000 | PASS |
| C14 | first_yoy K10 vs original source | 2435.5084989609 | 2435.5084989609 | PASS |
| C14 | group_product_intersection K06 vs original source | 2115.0000000000 | 2115.0000000000 | PASS |
| C14 | group_product_intersection K09 vs original source | 2.0000000000 | 2.0000000000 | PASS |
| C14 | group_product_intersection K10 vs original source | 136.1069739952 | 136.1069739952 | PASS |
| C14 | group_union K06 vs original source | 13617.0000000000 | 13617.0000000000 | PASS |
| C14 | group_union K09 vs original source | 14.0000000000 | 14.0000000000 | PASS |
| C14 | group_union K10 vs original source | 346.9916611588 | 346.9916611588 | PASS |
| C14 | Invoice distinct counts not additive across products | 1.0000000000 | 1.0000000000 | PASS |
| C14 | K06 distinct invoices | 70510.0000000000 | 70510.0000000000 | PASS |
| C14 | K09 products | 227.0000000000 | 227.0000000000 | PASS |
| C14 | K10 baseline | 2443.0767437242 | 2443.0767437242 | PASS |
| C14 | leap_yoy K06 vs original source | 1655.0000000000 | 1655.0000000000 | PASS |
| C14 | leap_yoy K09 vs original source | 227.0000000000 | 227.0000000000 | PASS |
| C14 | leap_yoy K10 vs original source | 2420.3122960725 | 2420.3122960725 | PASS |
| C14 | mom K06 vs original source | 1857.0000000000 | 1857.0000000000 | PASS |
| C14 | mom K09 vs original source | 219.0000000000 | 219.0000000000 | PASS |
| C14 | mom K10 vs original source | 2412.8866720516 | 2412.8866720516 | PASS |
| C14 | negative_only K06 vs original source | 4494.0000000000 | 4494.0000000000 | PASS |
| C14 | negative_only K09 vs original source | 18.0000000000 | 18.0000000000 | PASS |
| C14 | negative_only K10 vs original source | 1104.3523475745 | 1104.3523475745 | PASS |
| C14 | no_group_selection K06 vs original source | 9190.0000000000 | 9190.0000000000 | PASS |
| C14 | no_group_selection K09 vs original source | 227.0000000000 | 227.0000000000 | PASS |
| C14 | no_group_selection K10 vs original source | 2462.8047388465 | 2462.8047388465 | PASS |
| C14 | non_special_positive K06 vs original source | 9177.0000000000 | 9177.0000000000 | PASS |
| C14 | non_special_positive K09 vs original source | 223.0000000000 | 223.0000000000 | PASS |
| C14 | non_special_positive K10 vs original source | 2399.5501906941 | 2399.5501906941 | PASS |
| C14 | null_buying_group K06 vs original source | 26029.0000000000 | 26029.0000000000 | PASS |
| C14 | null_buying_group K09 vs original source | 227.0000000000 | 227.0000000000 | PASS |
| C14 | null_buying_group K10 vs original source | 2440.6890660417 | 2440.6890660417 | PASS |
| C14 | outside K06 vs original source | None | None | PASS |
| C14 | outside K09 vs original source | None | None | PASS |
| C14 | outside K10 vs original source | None | None | PASS |
| C14 | Partial item revenue does not retrieve entire baskets | 1.0000000000 | 1.0000000000 | PASS |
| C14 | partial_basket K06 vs original source | 1048.0000000000 | 1048.0000000000 | PASS |
| C14 | partial_basket K09 vs original source | 1.0000000000 | 1.0000000000 | PASS |
| C14 | partial_basket K10 vs original source | 134.8687977099 | 134.8687977099 | PASS |
| C14 | partial_month K06 vs original source | 1948.0000000000 | 1948.0000000000 | PASS |
| C14 | partial_month K09 vs original source | 227.0000000000 | 227.0000000000 | PASS |
| C14 | partial_month K10 vs original source | 2551.8134753593 | 2551.8134753593 | PASS |
| C14 | Product distinct counts not additive across buyers | 1.0000000000 | 1.0000000000 | PASS |
| C14 | product_axis K06 vs original source | 70510.0000000000 | 70510.0000000000 | PASS |
| C14 | product_axis K09 vs original source | 227.0000000000 | 227.0000000000 | PASS |
| C14 | product_axis K10 vs original source | 2443.0767437242 | 2443.0767437242 | PASS |
| C14 | selected_buyers K06 vs original source | 123.0000000000 | 123.0000000000 | PASS |
| C14 | selected_buyers K09 vs original source | 189.0000000000 | 189.0000000000 | PASS |
| C14 | selected_buyers K10 vs original source | 2483.6943089430 | 2483.6943089430 | PASS |
| C14 | selected_products K06 vs original source | 1048.0000000000 | 1048.0000000000 | PASS |
| C14 | selected_products K09 vs original source | 1.0000000000 | 1.0000000000 | PASS |
| C14 | selected_products K10 vs original source | 134.8687977099 | 134.8687977099 | PASS |
| C14 | special_only K06 vs original source | 476.0000000000 | 476.0000000000 | PASS |
| C14 | special_only K09 vs original source | 14.0000000000 | 14.0000000000 | PASS |
| C14 | special_only K10 vs original source | 46.1332983193 | 46.1332983193 | PASS |
| C14 | sunday K06 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C14 | sunday K09 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C14 | sunday K10 vs original source | None | None | PASS |
| C14 | ytd_2016 K06 vs original source | 9190.0000000000 | 9190.0000000000 | PASS |
| C14 | ytd_2016 K09 vs original source | 227.0000000000 | 227.0000000000 | PASS |
| C14 | ytd_2016 K10 vs original source | 2462.8047388465 | 2462.8047388465 | PASS |
| C14 | zero_base K06 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C14 | zero_base K09 vs original source | 0.0000000000 | 0.0000000000 | PASS |
| C14 | zero_base K10 vs original source | None | None | PASS |
| C15 | Civil calendar days | 1247.0000000000 | 1247.0000000000 | PASS |
| C15 | Civil calendar months | 41.0000000000 | 41.0000000000 | PASS |
| C15 | Full years and 2016 YTD coverage | 0.0000000000 | 0.0000000000 | PASS |
| C15 | No calendar dates outside coverage | 0.0000000000 | 0.0000000000 | PASS |
| C15 | Outside coverage: all 21 N/A | 0.0000000000 | 0.0000000000 | PASS |
| C15 | Sunday inside coverage: zero sales | 0.0000000000 | 0.0000000000 | PASS |
| C16 | annual_2014 K13 | 4222299.2000000000 | 4222299.2000000000 | PASS |
| C16 | annual_2014 K14 | 9.2377137700 | 9.2377137700 | PASS |
| C16 | annual_2014 K15 | 2060110.2000000000 | 2060110.2000000000 | PASS |
| C16 | annual_2014 K16 | -0.0864519400 | -0.0864519400 | PASS |
| C16 | Dense month LAG coverage edges | 0.0000000000 | 0.0000000000 | PASS |
| C16 | LAG MoM matches civil previous month for all 41 months | 0.0000000000 | 0.0000000000 | PASS |
| C16 | LAG YoY matches previous year for all 41 months | 0.0000000000 | 0.0000000000 | PASS |
| C16 | Leap day retained | 1.0000000000 | 1.0000000000 | PASS |
| C16 | leap_yoy K13 | -189702.4000000000 | -189702.4000000000 | PASS |
| C16 | leap_yoy K14 | -4.5217631500 | -4.5217631500 | PASS |
| C16 | leap_yoy K15 | -136957.0500000000 | -136957.0500000000 | PASS |
| C16 | leap_yoy K16 | -1.0342713600 | -1.0342713600 | PASS |
| C16 | mom K13 | -592534.2000000000 | -592534.2000000000 | PASS |
| C16 | mom K14 | -11.6795442200 | -11.6795442200 | PASS |
| C16 | mom K15 | -309779.0500000000 | -309779.0500000000 | PASS |
| C16 | mom K16 | -0.3178629900 | -0.3178629900 | PASS |
| C16 | Unavailable, partial and discontinuous temporal comparisons | 0.0000000000 | 0.0000000000 | PASS |
| C16 | ytd_2016 K13 | -45969.9000000000 | -45969.9000000000 | PASS |
| C16 | ytd_2016 K14 | -0.2026967900 | -0.2026967900 | PASS |
| C16 | ytd_2016 K15 | -162311.8500000000 | -162311.8500000000 | PASS |
| C16 | ytd_2016 K16 | -0.6156094100 | -0.6156094100 | PASS |
| C16 | zero_base K13 | 0.0000000000 | 0.0000000000 | PASS |
| C16 | zero_base K14 | None | None | PASS |
| C16 | zero_base K15 | 0.0000000000 | 0.0000000000 | PASS |
| C16 | zero_base K16 | None | None | PASS |
| C17 | Buyer delivery geography | 0.0000000000 | 0.0000000000 | PASS |
| C17 | Historical buyer attributes equal accepted current snapshot | 0.0000000000 | 0.0000000000 | PASS |
| C17 | No missing customer categories | 0.0000000000 | 0.0000000000 | PASS |
| C17 | Null buying groups preserved | 261.0000000000 | 261.0000000000 | PASS |
| C17 | Optional missing brands retained | 209.0000000000 | 209.0000000000 | PASS |
| C18 | Partition BillToCustomerID | 228265 | 228265 and four exact totals | PASS |
| C18 | Partition CustomerID | 228265 | 228265 and four exact totals | PASS |
| C18 | Partition DateKey/100 | 228265 | 228265 and four exact totals | PASS |
| C18 | Partition IsNegative | 228265 | 228265 and four exact totals | PASS |
| C18 | Partition IsNegative,IsSpecial | 228265 | 228265 and four exact totals | PASS |
| C18 | Partition IsSpecial | 228265 | 228265 and four exact totals | PASS |
| C18 | Partition StockItemID | 228265 | 228265 and four exact totals | PASS |
| C19 | All 21 metric IDs returned | 21.0000000000 | 21.0000000000 | PASS |
| C19 | Context and lineage on every metric | 0.0000000000 | 0.0000000000 | PASS |
| C01 | Runner completed without SQL errors | None | None | PASS |
| C01 | Official backup SHA256 | 066279a8cd28c8d85cbd8215ea71a5d672b420cfbc19756b635c27bd8027dada | 066279a8cd28c8d85cbd8215ea71a5d672b420cfbc19756b635c27bd8027dada | PASS |
| C01 | Previously existing evidence unchanged | True | True | PASS |
| C01 | Historical evidence hash: inventory.json | c82d111be94df0d3947275b3bad166443effd69882c9956e733184b65af23d44 | c82d111be94df0d3947275b3bad166443effd69882c9956e733184b65af23d44 | PASS |
| C01 | Historical evidence hash: audit.json | e712466fd340b6b2cf8b1db77847dd460237b03b511082d5ec4fa55f718b5e0c | e712466fd340b6b2cf8b1db77847dd460237b03b511082d5ec4fa55f718b5e0c | PASS |
| C01 | Historical evidence hash: followup.json | 197ba646002fd92550d4d66c0b45ef5e9641547786a5f1f43f425d007a08777f | 197ba646002fd92550d4d66c0b45ef5e9641547786a5f1f43f425d007a08777f | PASS |
| C01 | Historical evidence hash: exceptions.json | e7620574b49fb052f5f54b3d96ebb27375a12f6306964fe814ad74be46f34446 | e7620574b49fb052f5f54b3d96ebb27375a12f6306964fe814ad74be46f34446 | PASS |
| C01 | Historical evidence hash: pricing_semantics.json | 528529f4355fc317d8b35f889af99a2e1c810cf4608d89449b35426b24563ff0 | 528529f4355fc317d8b35f889af99a2e1c810cf4608d89449b35426b24563ff0 | PASS |
| C01 | Historical evidence hash: integrity.json | 28a1d12e26a85f039bb2856f82bdd77078be47036c8b3693d4df28b13113981d | 28a1d12e26a85f039bb2856f82bdd77078be47036c8b3693d4df28b13113981d | PASS |
| C01 | Historical evidence hash: source_manifest.json | 0dcb50548ff5ccec04bfe49fe2e2afcf60016d973fc62c039f8e1fb7d4fe1f59 | 0dcb50548ff5ccec04bfe49fe2e2afcf60016d973fc62c039f8e1fb7d4fe1f59 | PASS |
| C01 | Historical evidence hash: environment.json | e973902486e91bc158d3b9cc81da3ccd80aa2401e1f786333df93415f7922b9c | e973902486e91bc158d3b9cc81da3ccd80aa2401e1f786333df93415f7922b9c | PASS |
| C01 | Historical evidence hash: final_environment.json | 6ae66d59119bcaa26b25560624534f8c150394642fb96742a88cf504dd5cdba5 | 6ae66d59119bcaa26b25560624534f8c150394642fb96742a88cf504dd5cdba5 | PASS |
| C19 | Normal LocalDB stop | 0 | 0 | PASS |
| C19 | Disk guard respected at recorded checkpoints | True | True | PASS |
| C04 | Independent Decimal K01, exact cents | 172261341.2000000000 | 172261341.20 | PASS |
| C04 | Independent Decimal K02, exact cents | 25782098.2500000000 | 25782098.25 | PASS |
| C04 | Independent Decimal K03, exact cents | 198043439.4500000000 | 198043439.45 | PASS |
| C04 | Independent Decimal K04, exact cents | 85729180.9000000000 | 85729180.90 | PASS |
| C06 | Independent high-precision margin bound (1e-8 pp) | True | True | PASS |
| C06 | Independent four-place margin display | 49.7669 | 49.7669 | PASS |
| C14 | Independent high-precision baseline ticket bound (1e-10 UM) | True | True | PASS |
| C07 | Independent K18 incidence bound (1e-8 pp) | True | True | PASS |
| C19 | Resumption normal stop | 0 | 0 | PASS |
| C01 | Resumption protected files unchanged | True | True | PASS |
| C19 | Resumption disk checkpoints >=2 GiB | True | True | PASS |
| C02 | Resumption catalog FactInvoiceLine | 228265 | 228265 | PASS |
| C02 | Resumption catalog DimBuyer | 663 | 663 | PASS |
| C02 | Resumption catalog DimBillingAccount | 263 | 263 | PASS |
| C02 | Resumption catalog DimProduct | 227 | 227 | PASS |
| C02 | Resumption catalog DimDate | 1247 | 1247 | PASS |
| C02 | Resumption catalog DimGeography | 655 | 655 | PASS |
| C02 | Resumption catalog DimStockGroup | 10 | 10 | PASS |
| C02 | Resumption catalog BridgeProductGroup | 442 | 442 | PASS |
| C02 | Resumption catalog DimSpecialDeal | 2 | 2 | PASS |
| C03 | Resumption nine FKs enabled and trusted | True | True | PASS |
| C19 | Deployed module body matches file: Kpis | True | True | PASS |
| C19 | Deployed module body matches file: MonthlyControl | True | True | PASS |
| C19 | Deployed module body matches file: SafeRatio | True | True | PASS |
| C19 | Deployed module body matches file: SelectedLines | True | True | PASS |
| C19 | Runner accepts PASS | True | True | PASS |
| C19 | Runner rejects FAIL | True | True | PASS |
| C19 | Runner rejects missing assertions | True | True | PASS |
