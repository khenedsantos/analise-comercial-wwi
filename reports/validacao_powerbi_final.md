# ValidaÃ§Ã£o final â€” Power BI WWI

Registro de fechamento documental em 06/10/2026. O PBIP foi salvo e validado manualmente pelo autor no Desktop; o PBIX final foi regenerado apÃ³s a padronizaÃ§Ã£o numÃ©rica e a aprovaÃ§Ã£o visual final das oito pÃ¡ginas. O arquivo foi modificado em 06/10/2026 Ã s 16:03:24 (UTCâˆ’03:00). Nesta etapa documental, nenhum arquivo Power BI, SQL, modelo ou script de validaÃ§Ã£o foi alterado; nÃ£o houve refresh ou nova execuÃ§Ã£o DAX/SQL.

## Camadas de evidÃªncia

| Camada | Resultado e origem |
| --- | --- |
| SQL/modelo dimensional | 607 PASS / 0 FAIL histÃ³ricos; 565 asserts SQL persistidos + 42 verificaÃ§Ãµes complementares |
| DAX Query View | 85 PASS / 0 FAIL, execuÃ§Ã£o manual confirmada pelo autor usando validacao_desktop.dax |
| PÃ¡ginas 01â€“08 | AprovaÃ§Ã£o visual manual do autor; oito screenshots finais disponibilizadas |
| Auditoria final do report layer | PASS COM RESSALVAS: referÃªncias, metadados, canvas, queries, filtros, escopo e schema auxiliar |
| Esta etapa | ConferÃªncia do tamanho/hash do PBIX, cÃ³pia idÃªntica das imagens, links e preservaÃ§Ã£o dos arquivos protegidos |

Fontes: [validaÃ§Ã£o da Etapa 4](validacao_etapa4.md), [evidÃªncia SQL](../data/metadata/stage4-20260930-120408.json), [fechamento SQL](../data/metadata/stage4-closeout.json), [consulta DAX](../powerbi/validacao_desktop.dax). O resultado manual Desktop nÃ£o deve ser confundido com execuÃ§Ã£o automatizada nesta etapa; nÃ£o foi criado um log fictÃ­cio de 85 testes.

## Artefatos finais

- [PBIP](../powerbi/analise_comercial_wwi.pbip): estrutura versionÃ¡vel do relatÃ³rio e referÃªncia ao modelo semÃ¢ntico.
- [PBIX](../powerbi/analise_comercial_wwi.pbix): artefato salvo pelo Desktop com dados importados.
- Tamanho do PBIX conferido: **5.881.598 bytes / 5,609129 MiB**, abaixo do limite preventivo de 95 MiB adotado pelo projeto.
- SHA-256 conferido:

```text
59790e542a37df2b3288a09e9beb97e555b2ed2e0f97145e42fd5204b727bee7
```

O PBIX nÃ£o foi aberto no Desktop, regravado ou modificado pela preparaÃ§Ã£o tÃ©cnica/documental. Seu conteÃºdo interno nÃ£o foi inspecionado por esta verificaÃ§Ã£o de hash.

## NavegaÃ§Ã£o e inventÃ¡rio

Nove pÃ¡ginas totais; oito visÃ­veis. `00_ValidaÃ§Ã£o` permanece vazia, preservada e oculta por `HiddenInViewMode`. A validaÃ§Ã£o DAX real foi feita no Query View, nÃ£o nessa pÃ¡gina. `activePageName` aponta para Q01.

1. 01_Q01_Evolucao
2. 02_Q02_Produtos
3. 03_Q03_Clientes
4. 04_Q04_Concentracao
5. 05_Q05_Negativos
6. 06_Q06_Geografia
7. 07_Q07_Mix_Especiais
8. 08_Recomendacoes_Executivas

A auditoria inventariou **71 visuais e 37 consultas analÃ­ticas**. NÃ£o encontrou visuais fora do canvas, dimensÃµes invÃ¡lidas ou diretÃ³rios de pÃ¡ginas/visuais Ã³rfÃ£os. As sobreposiÃ§Ãµes eram Ã­cones/badges previstos. Pequenas diferenÃ§as de posiÃ§Ã£o aprovadas manualmente foram preservadas. NÃ£o se trata de uma renderizaÃ§Ã£o automatizada.

## PreservaÃ§Ã£o analÃ­tica

O modelo semÃ¢ntico permaneceu logicamente inalterado; apenas format strings de 22 medidas monetÃ¡rias foram ajustadas para padronizaÃ§Ã£o visual, removendo o literal UM. ExpressÃµes DAX, relacionamentos, tabelas, colunas e Power Query foram preservados. ComparaÃ§Ãµes com os snapshots confirmam essas alteraÃ§Ãµes restritas; SQL e regras analÃ­ticas permanecem intactos. Os overrides locais mantÃªm mi/mil e a precisÃ£o aprovada. O autor confirmou a escala de milhÃµes da Q01 no Desktop. Nesta sincronizaÃ§Ã£o, nenhum arquivo do modelo ou Report foi editado.

As 37 consultas e seus filtros foram conferidos; campos, cÃ¡lculos e filtros permanecem preservados. ALTERAÃ‡ÃƒO MANUAL APROVADA: a tabela detalhada da Q02 (deabd05b83a752df01cb) passou de Ascending para Descending por K15 VariaÃ§Ã£o de lucro â€” YTD, conforme confirmaÃ§Ã£o explÃ­cita do autor. Trata-se de ordenaÃ§Ã£o da apresentaÃ§Ã£o, sem alteraÃ§Ã£o de lÃ³gica analÃ­tica. As demais ordenaÃ§Ãµes foram preservadas, incluindo Top/Bottom da Q02, CR5 e Top 5 da Q04, linhas negativas > 0 da Q05, produtos da Q06 e contextos histÃ³rico/comparÃ¡vel da Q07. Na Q06, vendas > 0 jÃ¡ existia apenas no segundo controle; essa diferenÃ§a foi mantida.

InvoiceDate permanece a data oficial. Buyer e Billing Account sÃ£o distintos. Margem Ã© razÃ£o agregada. Stock Groups se sobrepÃµem e a ponte nÃ£o pode multiplicar a fato. K12 nÃ£o se aplica a Stock Group. As notas metodolÃ³gicas Q06/Q07 e os textos executivos Q08 foram preservados.

## LimitaÃ§Ãµes de tooling/schema

O schema visual original `2.13.0` estava indisponÃ­vel (HTTP 404). A verificaÃ§Ã£o auxiliar dos 71 visuais usou o schema publicado `2.7.0` em memÃ³ria, sem converter o projeto nem trocar suas declaraÃ§Ãµes. Outros 14 arquivos passaram nos schemas disponÃ­veis; dois recursos de tema foram lidos como JSON vÃ¡lido. Isso nÃ£o equivale a validaÃ§Ã£o integral pelo schema original indisponÃ­vel.

`verify_preparation.py` continua apresentando a ocorrÃªncia conhecida **KeyError: 'isActive'**. O modelo semÃ¢ntico permaneceu logicamente inalterado, exceto pela apresentaÃ§Ã£o numÃ©rica das format strings monetÃ¡rias; sua validaÃ§Ã£o anterior no Desktop foi confirmada pelo autor. NÃ£o se tentou contornar a limitaÃ§Ã£o alterando o modelo ou o script.

## Capturas finais e integridade

Origem: `powerbi/screenshots/`. Destino: `docs/images/powerbi/`. As oito imagens foram copiadas sem recompressÃ£o, redimensionamento, recorte ou ediÃ§Ã£o. Cada hash abaixo corresponde tanto Ã  origem quanto ao destino; a igualdade tambÃ©m foi conferida byte a byte.

| Captura | SHA-256 (origem = destino) |
| --- | --- |
| [01_evolucao.png](../docs/images/powerbi/01_evolucao.png) | `ca12a32362e26a7cad52108ea8c3c6570bab1d89ca0201e859d4bd4f8be4e654` |
| [02_produtos.png](../docs/images/powerbi/02_produtos.png) | `3fcb3ee5ba46975aa00cddca220613484f863997c6a1b3d8ff112d3325c94732` |
| [03_clientes.png](../docs/images/powerbi/03_clientes.png) | `44c4d0e829bf6b71b279a82e7dbbc87a8f473b88e351c80ee51440da9af998d8` |
| [04_concentracao.png](../docs/images/powerbi/04_concentracao.png) | `cc3095c5a32ff63ba285c1fdb56bf7cac71c5287237fba37e1d452609b59e5cd` |
| [05_resultados_negativos.png](../docs/images/powerbi/05_resultados_negativos.png) | `410f5d1dfbdb16f74dd032059b80f992003e4d6a725b9fd515ebf2c6782e7338` |
| [06_geografia.png](../docs/images/powerbi/06_geografia.png) | `d959e12b375c4b1760fc48594292485ea9aecfdfb404274eff94b61adc23d76d` |
| [07_mix_condicoes_especiais.png](../docs/images/powerbi/07_mix_condicoes_especiais.png) | `0f6e8258ae70c13bd7cb2e42a2762ad8e56673690508da3ac9b2df14e01b7f03` |
| [08_recomendacoes_executivas.png](../docs/images/powerbi/08_recomendacoes_executivas.png) | `81b6ec1b0e721bf5b551ed066e5b7926960505299ccac0c9cfa2237ace16390b` |

## SincronizaÃ§Ã£o e auditoria final

As oito capturas finais foram refeitas pelo autor apÃ³s a padronizaÃ§Ã£o numÃ©rica e substituÃ­das nos destinos oficiais. NÃ£o hÃ¡ UM em format strings ativas do Report/SemanticModel. Permanecem referÃªncias documentais/histÃ³ricas e o literal no gerador powerbi/build_model.py, preservado nesta tarefa: regenerar o modelo por esse script pode reintroduzir o formato antigo.

Os 85 PASS / 0 FAIL sÃ£o da execuÃ§Ã£o manual anterior no DAX Query View, nÃ£o de nova execuÃ§Ã£o nesta sincronizaÃ§Ã£o. O PBIX foi apenas medido e submetido a hash, sem abertura, descompactaÃ§Ã£o ou inspeÃ§Ã£o interna.

## Contexto histÃ³rico e ressalvas de interpretaÃ§Ã£o

Os relatÃ³rios das Etapas 2â€“4 e da publicaÃ§Ã£o inicial conservam expressÃµes como â€œPower BI planejadoâ€, vÃ¡lidas Ã  data daqueles registros. README e documentos finais registram a conclusÃ£o posterior sem sobrescrever evidÃªncias. Os nÃºmeros histÃ³ricos conferidos sÃ£o compatÃ­veis com os controles fornecidos para esta entrega.

Os nomes curtos dos acordos na Q08 correspondem aos rÃ³tulos completos na Q07. Preserva-se a ressalva do diagnÃ³stico: o percentual da amostra multiplica o preÃ§o-base, nÃ£o representa desconto convencional. A participaÃ§Ã£o aproximada de 28% na queda de lucro Ã© uma comparaÃ§Ã£o aritmÃ©tica, nÃ£o inferÃªncia causal.

A aprovaÃ§Ã£o visual e os 85 PASS sÃ£o evidÃªncias manuais informadas pelo autor. As screenshots sÃ£o evidÃªncia visual do estado capturado; nÃ£o substituem o teste de todas as interaÃ§Ãµes possÃ­veis. NÃ£o houve publicaÃ§Ã£o, commit ou push nesta etapa.
