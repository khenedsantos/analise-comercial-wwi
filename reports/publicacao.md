# Auditoria pré-publicação — 01/10/2026

Escopo: preparar a primeira versão pública da fundação analítica WWI. Não houve nova análise comercial, criação de Power BI, restauração ou repetição da Etapa 4. As 607 verificações PASS / zero FAIL permanecem apoiadas no fechamento existente, incluindo C01–C19, K01–K21 e os 45 pares de Stock Groups.

## Checklist do conjunto candidato ao Git

- [x] Nenhuma credencial identificada na revisão de conteúdo e busca de padrões.
- [x] Nenhum `.env`.
- [x] Nenhum `.bak`.
- [x] Nenhum `.mdf`, `.ndf` ou `.ldf`.
- [x] Nenhum banco local, dump ou arquivo pessoal.
- [x] Nenhum cache, temporário ou log de instalação.
- [x] Nenhum output pesado regenerável.
- [x] README coerente com o estado implementado.
- [x] Documentação da Etapa 4, contrato, scripts e SQL presentes.
- [x] Metadata de fechamento e evidências de testes presentes.
- [x] Power BI não incluído; nenhuma conclusão comercial inventada.
- [x] Atribuição Microsoft e licença do material oficial preservadas.

O checklist se aplica aos arquivos selecionados para publicação, não à inexistência dos artefatos locais. A revisão de padrões procura tokens conhecidos, chaves privadas e atribuições de senha/segredo; ela foi acompanhada de revisão de origem e finalidade dos arquivos. Não constitui garantia universal de detecção de todo segredo possível.

## Arquivos locais preservados e excluídos

| Caminho | Tamanho aproximado | Tratamento |
| --- | ---: | --- |
| `data/raw/WideWorldImporters-Standard.bak` | 121,07 MiB | Backup necessário; ignorado |
| `data/sqlserver/WWI_Primary.mdf` | 1.024 MiB | Banco existente; ignorado |
| `data/sqlserver/WWI_UserData.ndf` | 2.048 MiB | Banco existente; ignorado |
| `data/sqlserver/WWI_Log.ldf` | 100 MiB | Log SQL; ignorado |
| `data/metadata/localdb-install-elevated.log` | 1,26 MiB | Log de instalação; ignorado |
| `data/metadata/localdb-install.log` | 70,60 KiB | Log de instalação; ignorado |

Nenhum desses arquivos foi removido da máquina. Os maiores arquivos publicados são `inventory.json` (aproximadamente 597 KiB), a evidência SQL Stage 4 (498 KiB) e `audit.json` (470 KiB). São evidências pequenas necessárias à rastreabilidade, não cópias do dataset.

Conexões usam Integrated Security, sem senha. Caminhos, nomes de máquina/conta e sessões em evidências antigas são contexto histórico, conforme [NOTICE](../NOTICE.md). Não foram sanitizados nem regravados; `stage4-closeout.json` foi preservado byte a byte. Os hashes históricos de README/.gitignore continuam retratando o fechamento anterior; suas mudanças posteriores ficam no Git. O endereço do commit foi configurado localmente para o noreply do GitHub, evitando expor o e-mail pessoal configurado globalmente.

## Mudanças necessárias para esta versão

| Arquivo | Alteração e motivo |
| --- | --- |
| `README.md` | Apresentação da fundação analítica, decisões, controles, limites, navegação e próximos passos reais |
| `.gitignore` | Proteção de credenciais, bancos, logs, caches, IDE, temporários e saídas locais, sem ocultar evidências JSON |
| `.gitattributes` | Desabilita conversão automática de finais de linha para preservar hashes auditados em clones |
| `scripts/acquire.py` | Preserva manifesto histórico existente; nova obtenção fica em `source_manifest.local.json` |
| `NOTICE.md` | Atribuição, licença Microsoft, ausência de licença autoral escolhida e significado dos caminhos históricos |
| `reports/reproducao.md` | Preparação da fonte, Build/Validate/Inspect, consulta dos KPIs e encerramento da instância |
| `reports/publicacao.md` | Este checklist e registro da revisão |

Não foram alterados contrato, três SQL, modelo analítico, valores de testes, runner Stage 4, verificador Stage 4 ou evidências anteriores. Nenhuma licença nova foi aplicada ao código autoral. A permissão de reutilização do material Microsoft acompanha as cópias oficiais.

## Verificações leves

- Sintaxe de todos os Python e PowerShell conferida sem executar carga ou consulta SQL.
- Fixture isolada da aquisição: manifesto antigo manteve bytes, manifesto local foi criado e não houve download/rede. A fixture não representa dados WWI nem adiciona testes aos 607 históricos.
- Hashes dos arquivos validados confrontados com `stage4-closeout.json`.
- Regras do runner inspecionadas: Build/Validate rejeitam FAIL e ausência de asserts; Inspect é somente catálogo e não se apresenta como nova validação.
- Pré-requisitos, caminhos relativos, sequência de comandos e política de parada revisados. Reprodução integral em máquina limpa não foi executada nesta publicação.

A pasta inicialmente não possuía `.git`. A publicação usa `main`, com um commit inicial honesto do trabalho desenvolvido localmente; não simula histórico anterior. Não cria `feature/power-bi` nem Pull Request. O estado final de Git/GitHub e a medição final de disco são entregues após a publicação, sem reescrever o fechamento histórico da Etapa 4.

Espaço inicial desta revisão: 3.787.833.344 bytes (aproximadamente 3,528 GiB). As operações de publicação exigem permanecer acima de 2 GiB; não há limpeza automática. LocalDB não foi iniciado nesta revisão.
