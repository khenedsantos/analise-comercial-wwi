# Validação final — Power BI WWI

Registro de fechamento documental em 06/10/2026. O PBIP foi salvo e validado manualmente pelo autor no Desktop; o PBIX final foi regenerado após a padronização numérica e a aprovação visual final das oito páginas. O arquivo foi modificado em 06/10/2026 às 16:03:24 (UTC−03:00). Nesta etapa documental, nenhum arquivo Power BI, SQL, modelo ou script de validação foi alterado; não houve refresh ou nova execução DAX/SQL.

## Camadas de evidência

| Camada | Resultado e origem |
| --- | --- |
| SQL/modelo dimensional | 607 PASS / 0 FAIL históricos; 565 asserts SQL persistidos + 42 verificações complementares |
| DAX Query View | 85 PASS / 0 FAIL, execução manual confirmada pelo autor usando validacao_desktop.dax |
| Páginas 01–08 | Aprovação visual manual do autor; oito screenshots finais disponibilizadas |
| Auditoria final do report layer | PASS COM RESSALVAS: referências, metadados, canvas, queries, filtros, escopo e schema auxiliar |
| Esta etapa | Conferência do tamanho/hash do PBIX, cópia idêntica das imagens, links e preservação dos arquivos protegidos |

Fontes: [validação da Etapa 4](validacao_etapa4.md), [evidência SQL](../data/metadata/stage4-20260930-120408.json), [fechamento SQL](../data/metadata/stage4-closeout.json), [consulta DAX](../powerbi/validacao_desktop.dax). O resultado manual Desktop não deve ser confundido com execução automatizada nesta etapa; não foi criado um log fictício de 85 testes.

## Artefatos finais

- [PBIP](../powerbi/analise_comercial_wwi.pbip): estrutura versionável do relatório e referência ao modelo semântico.
- [PBIX](../powerbi/analise_comercial_wwi.pbix): artefato salvo pelo Desktop com dados importados.
- Tamanho do PBIX conferido: **5.881.598 bytes / 5,609129 MiB**, abaixo do limite preventivo de 95 MiB adotado pelo projeto.
- SHA-256 conferido:

```text
59790e542a37df2b3288a09e9beb97e555b2ed2e0f97145e42fd5204b727bee7
```

O PBIX não foi aberto no Desktop, regravado ou modificado pela preparação técnica/documental. Seu conteúdo interno não foi inspecionado por esta verificação de hash.

## Navegação e inventário

Nove páginas totais; oito visíveis. `00_Validação` permanece vazia, preservada e oculta por `HiddenInViewMode`. A validação DAX real foi feita no Query View, não nessa página. `activePageName` aponta para Q01.

1. 01_Q01_Evolucao
2. 02_Q02_Produtos
3. 03_Q03_Clientes
4. 04_Q04_Concentracao
5. 05_Q05_Negativos
6. 06_Q06_Geografia
7. 07_Q07_Mix_Especiais
8. 08_Recomendacoes_Executivas

A auditoria inventariou **71 visuais e 37 consultas analíticas**. Não encontrou visuais fora do canvas, dimensões inválidas ou diretórios de páginas/visuais órfãos. As sobreposições eram ícones/badges previstos. Pequenas diferenças de posição aprovadas manualmente foram preservadas. Não se trata de uma renderização automatizada.

## Preservação analítica

O modelo semântico permaneceu logicamente inalterado; apenas format strings de 22 medidas monetárias foram ajustadas para padronização visual, removendo o literal UM. Expressões DAX, relacionamentos, tabelas, colunas e Power Query foram preservados. Comparações com os snapshots confirmam essas alterações restritas; SQL e regras analíticas permanecem intactos. Os overrides locais mantêm mi/mil e a precisão aprovada. O autor confirmou a escala de milhões da Q01 no Desktop. Nesta sincronização, nenhum arquivo do modelo ou Report foi editado.

As 37 consultas e seus filtros foram conferidos; campos, cálculos e filtros permanecem preservados. ALTERAÇÃO MANUAL APROVADA: a tabela detalhada da Q02 (deabd05b83a752df01cb) passou de Ascending para Descending por K15 Variação de lucro — YTD, conforme confirmação explícita do autor. Trata-se de ordenação da apresentação, sem alteração de lógica analítica. As demais ordenações foram preservadas, incluindo Top/Bottom da Q02, CR5 e Top 5 da Q04, linhas negativas > 0 da Q05, produtos da Q06 e contextos histórico/comparável da Q07. Na Q06, vendas > 0 já existia apenas no segundo controle; essa diferença foi mantida.

InvoiceDate permanece a data oficial. Buyer e Billing Account são distintos. Margem é razão agregada. Stock Groups se sobrepõem e a ponte não pode multiplicar a fato. K12 não se aplica a Stock Group. As notas metodológicas Q06/Q07 e os textos executivos Q08 foram preservados.

## Limitações de tooling/schema

O schema visual original `2.13.0` estava indisponível (HTTP 404). A verificação auxiliar dos 71 visuais usou o schema publicado `2.7.0` em memória, sem converter o projeto nem trocar suas declarações. Outros 14 arquivos passaram nos schemas disponíveis; dois recursos de tema foram lidos como JSON válido. Isso não equivale a validação integral pelo schema original indisponível.

`verify_preparation.py` continua apresentando a ocorrência conhecida **KeyError: 'isActive'**. O modelo semântico permaneceu logicamente inalterado, exceto pela apresentação numérica das format strings monetárias; sua validação anterior no Desktop foi confirmada pelo autor. Não se tentou contornar a limitação alterando o modelo ou o script.

## Capturas finais e integridade

Origem: `powerbi/screenshots/`. Destino: `docs/images/powerbi/`. As oito imagens foram copiadas sem recompressão, redimensionamento, recorte ou edição. Cada hash abaixo corresponde tanto à origem quanto ao destino; a igualdade também foi conferida byte a byte.

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

## Sincronização e auditoria final

As oito capturas finais foram refeitas pelo autor após a padronização numérica e substituídas nos destinos oficiais. Não há UM em format strings ativas do Report/SemanticModel. Permanecem referências documentais/históricas e o literal no gerador powerbi/build_model.py, preservado nesta tarefa: regenerar o modelo por esse script pode reintroduzir o formato antigo.

Os 85 PASS / 0 FAIL são da execução manual anterior no DAX Query View, não de nova execução nesta sincronização. O PBIX foi apenas medido e submetido a hash, sem abertura, descompactação ou inspeção interna.

## Contexto histórico e ressalvas de interpretação

Os relatórios das Etapas 2–4 e da publicação inicial conservam expressões como “Power BI planejado”, válidas à data daqueles registros. README e documentos finais registram a conclusão posterior sem sobrescrever evidências. Os números históricos conferidos são compatíveis com os controles fornecidos para esta entrega.

Os nomes curtos dos acordos na Q08 correspondem aos rótulos completos na Q07. Preserva-se a ressalva do diagnóstico: o percentual da amostra multiplica o preço-base, não representa desconto convencional. A participação aproximada de 28% na queda de lucro é uma comparação aritmética, não inferência causal.

A aprovação visual e os 85 PASS são evidências manuais informadas pelo autor. As screenshots são evidência visual do estado capturado; não substituem o teste de todas as interações possíveis. Não houve publicação, commit ou push nesta etapa.
