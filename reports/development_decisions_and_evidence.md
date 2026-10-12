# Decisões de desenvolvimento e evidências

Índice de referências do case sintético WWI. **A — Comprovada:** há código, teste,
relatório ou artefato identificável. **B — Parcial:** implementação verificável,
mas execução, proveniência ou atribuição incompleta. **C — Não comprovada:** requer
confirmação pessoal ou evidência adicional. As classes não medem autoria humana exclusiva.

## 1. Evolução e limites do histórico Git

**A — Entregas:** [50b0e98](https://github.com/khenedsantos/analise-comercial-wwi/commit/50b0e98)
introduz o modelo analítico validado; [188298f](https://github.com/khenedsantos/analise-comercial-wwi/commit/188298f)
acrescenta o Power BI. São os dois commits existentes na auditoria documental.
**B — Processo:** os [relatórios de etapas](modelo_etapa4.md) e os registros em
[data/metadata](../data/metadata/) oferecem detalhes intermediários, mas o Git não
isola cada tentativa ou correção. Metadados de commit não identificam quem concebeu uma solução.

## 2. Decisões de modelagem dimensional

**A — Decisões documentadas e implementação:** o [contrato](contrato_analitico_etapa3.md)
e o [modelo](modelo_etapa4.md) definem grão por `InvoiceLineID`, data oficial
`InvoiceDate`, Buyer separado de Billing Account e dimensões com chaves do snapshot.
O [DDL](../sql/01_model.sql) implementa PKs/FKs; a equivalência dos atributos históricos
é verificada, sem alegar historização completa.

**A — Ponte:** [SelectedLines](../sql/02_metrics.sql) usa `EXISTS` para selecionar a
união de produtos, sem multiplicar a fato. Participações de Stock Groups não são
aditivas; CR5 não se aplica a esse eixo. As sentinelas do join incorreto e os controles
de união estão em [03_validation.sql](../sql/03_validation.sql). São controles de
prevenção, não evidência de erro de produção corrigido.

## 3. Qualidade, SQL e reconciliação financeira

| Evidência de execução — A | Referência e alcance |
|---|---|
| 565 asserções SQL persistidas, todas PASS | [Execução SQL](../data/metadata/stage4-20260930-120408.json). As 567 observações de KPIs não são testes adicionais. |
| 607 verificações individuais: 565 + 42 complementares | [Validação consolidada](validacao_etapa4.md), [fechamento](../data/metadata/stage4-closeout.json). Não somar 607 a 565. |
| Reconciliação K01–K05 e integridade | [Verificador](../scripts/verify_stage4.py), [contrato](contrato_analitico_etapa3.md): centavos exatos nas somas e limite de representação decimal nas razões, não tolerância monetária. |

Os contratos abrangem IDs, grão, relações, calendário, sinais e filtros. A evidência
refere-se ao snapshot e aos cenários testados; não prova completude de uma empresa real.
Nenhuma suíte foi reexecutada para criar este índice.

## 4. Modelo semântico, DAX e Power BI

**A — Implementação:** [model.bim](../powerbi/WWI.SemanticModel/model.bim) contém dez
tabelas incluindo `_Medidas`, oito relações e 60 medidas. Margem é razão de somas;
CR5 usa seleção externa e desempate por ID. Há propagação bidirecional específica
entre produto e ponte, não um modelo inteiramente unidirecional.

**A/B — Validação:** [validacao_desktop.dax](../powerbi/validacao_desktop.dax) contém
85 testes; os **85 PASS / 0 FAIL são registrados como execução manual confirmada pelo
autor**, sem log automatizado equivalente. O [fechamento Power BI](validacao_powerbi_final.md)
distingue essa confirmação das verificações estruturais e das capturas. Screenshots
não substituem testes de todas as interações. A apresentação usa mi/mil sem moeda
real presumida; `LineProfit` não é lucro líquido nem EBITDA.

## 5. Decisões comerciais e limites analíticos

**A — Resultados e recomendações documentados:** a [análise Q01–Q07](analise_executiva_powerbi.md)
liga deterioração de margem, concentração por conta de cobrança, SKUs negativos e
mix a prioridades de investigação. Preserva perdas e separa participação nas vendas,
incidência de linhas negativas e contribuição aritmética para variação do lucro.

O [diagnóstico](diagnostico_etapa2.md) e a [função Microsoft preservada](../data/metadata/embedded_modules/Website.CalculateCustomerPrice.sql)
mostram que o percentual especial multiplica o preço-base; não é desconto convencional.
Os registros originais não foram corrigidos. Dados sintéticos, custos incompletos,
período final parcial e grupos sobrepostos limitam a interpretação. Não há impacto
financeiro realizado, ganho recuperável estimado ou efeito causal demonstrado.

## 6. Problemas técnicos e correções comprovadas

- **A — Timeout e retomada:** a [primeira tentativa](../data/metadata/stage4-20260930-115845.json)
  registra falha; a execução SQL posterior registra conclusão. A divisão em lotes
  está documentada no [modelo](modelo_etapa4.md) e implementada no [runner](../scripts/run_stage4.ps1).
  A tentativa incompleta não é contada como aprovação.
- **A — Comparação de módulos:** o [verificador](../scripts/verify_stage4.py) normaliza
  somente cabeçalho `CREATE`/`CREATE OR ALTER` e finais de linha. Os [quatro registros](../data/metadata/stage4-module-checks.json)
  confirmam equivalência após normalização; não demonstram alteração de lógica SQL.
- **B — Limitações ainda presentes:** o [fechamento](validacao_powerbi_final.md) registra
  `KeyError: 'isActive'` no verificador e schema 2.13 indisponível, com checagem auxiliar
  em 2.7. Não são problemas resolvidos. O gerador preservado pode reintroduzir a
  formatação monetária antiga; não se deve confundir geração com o artefato final salvo.

## 7. Evidência técnica, contribuição pessoal e IA

Implementação, execução registrada e justificativa metodológica são evidências
distintas. **C — Atribuição individual:** o repositório não discrimina quem propôs,
revisou ou implementou cada decisão. Experiência profissional e domínio técnico não
são demonstrados apenas pelos artefatos. O [roteiro de estudo](technical_interview_preparation.md)
indica demonstrações possíveis, sem respostas pessoais inventadas.

### Assistência de inteligência artificial

Este projeto foi desenvolvido com apoio de ferramentas de inteligência artificial durante o processo de desenvolvimento e documentação.

O repositório disponibiliza implementações, decisões metodológicas, testes, resultados e limitações que permitem examinar tecnicamente a solução.

A utilização dessas ferramentas não deve ser interpretada como desenvolvimento exclusivamente manual, assim como os registros do repositório não permitem atribuir individualmente cada decisão ou implementação.
