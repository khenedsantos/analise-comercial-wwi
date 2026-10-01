# Reprodução da fundação analítica

Execute os comandos a partir da raiz do repositório. O ambiente usado foi Windows 11, LocalDB 2025 17.0.1000.7, Windows PowerShell 5.1/.NET SqlClient e Python 3.14.6. Não há pacotes Python externos. Instale previamente o LocalDB pela [Microsoft](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/sql-server-express-localdb); sua instalação não é automatizada aqui.

## Conferir somente a evidência publicada

```powershell
python scripts/verify_stage4.py
```

O comando não se conecta ao banco: lê os resultados persistidos, confere hashes históricos e razões com Decimal, e gera `reports/validacao_etapa4.md`. Os 607 PASS representam a execução registrada da Etapa 4, não uma nova execução SQL nesta máquina. Os caminhos absolutos presentes em JSONs históricos são contexto da máquina original, não caminhos a criar.

## Preparar uma fonte nova

Não execute esta seção se o banco já estiver restaurado. Reserve espaço para 121,07 MiB de backup, 3.172 MiB de arquivos SQL e pelo menos 2 GiB livres após a restauração; o runner interrompe abaixo dessa reserva. Não executa limpeza automática.

```powershell
python scripts/acquire.py
if ($LASTEXITCODE -ne 0) { throw 'Aquisição falhou.' }
$wwiLocalDb = 'C:\Program Files\Microsoft SQL Server\170\Tools\Binn\SqlLocalDB.exe'
& $wwiLocalDb create WWI_Portfolio 17.0 -s
if ($LASTEXITCODE -ne 0) { throw 'Criação da instância falhou; inspecione antes de continuar.' }
try {
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/query.ps1 -SqlFile scripts/backup_inspection.sql -Database master -OutputFile data/metadata/backup_inspection.json
    if ($LASTEXITCODE -ne 0) { throw 'Inspeção do backup falhou.' }
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/query.ps1 -SqlFile scripts/configure_instance.sql -Database master -OutputFile data/metadata/instance_configuration.json
    if ($LASTEXITCODE -ne 0) { throw 'Configuração falhou.' }
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/restore.ps1
    if ($LASTEXITCODE -ne 0) { throw 'Restauração falhou.' }
} finally {
    & $wwiLocalDb stop WWI_Portfolio
}
```

`acquire.py` usa a release oficial, reutiliza backup íntegro e rejeita SHA-256 diferente do contrato. Preserva o manifesto histórico versionado: informações da nova obtenção vão para `data/metadata/source_manifest.local.json`, ignorado pelo Git. A documentação de origem já presente permanece fixada no commit do manifesto.

A instância é `(localdb)\WWI_Portfolio`; banco `WWI_Portfolio_Diagnostic`. Conexão por autenticação integrada da conta Windows proprietária da instância, sem senha. O caminho acima é o padrão do LocalDB 2025, não um caminho pessoal. Se a instalação estiver em outro local, ajuste esse caminho e `$localdb` no runner. Não use instância compartilhada com outro projeto: as configurações aplicam teto de memória de 512 MiB e MAXDOP 1.

Os comandos de preparação gravam novos resultados de inspeção/restauração na cópia de trabalho. Não faça commit dessas substituições como se fossem as evidências originais. Os relatórios históricos e `stage4-closeout.json` continuam descrevendo a execução original; os novos arquivos Stage 4 têm timestamp próprio. Não é necessário repetir a auditoria completa da Etapa 2 para criar analytics.

## Criar o modelo e validar

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/run_stage4.ps1 -Mode Build
if ($LASTEXITCODE -ne 0) { throw 'Build/validação falhou; leia a evidência salva.' }
python scripts/verify_stage4.py
```

`Build` executa os três SQL, uma vez, e recusa sobrescrever um esquema analytics existente. `Validate` executa somente os testes; `Inspect` consulta apenas catálogo, FKs e módulos. Os três modos encerram a instância em `finally`. Falha de assert ou ausência de verificações faz Build/Validate retornar erro. Cada execução salva `data/metadata/stage4-<timestamp>.json`.

Controles esperados: 228.265 linhas, 70.510 faturas, 663 compradores, 263 contas, 227 produtos; vendas sem impostos 172.261.341,20; impostos 25.782.098,25; faturamento 198.043.439,45; lucro registrado 85.729.180,90; margem 49,7669%. Veja [C01–C19](contrato_analitico_etapa3.md#10-contratostestes-de-aceitação-do-futuro-modelo).

## Executar métricas no banco preparado

Sem instalar SSMS, salve uma consulta local, por exemplo `consulta.local.sql`, contendo:

```sql
EXEC analytics.Kpis @Start='20160101', @End='20160531';
```

Depois execute (o resultado local não deve ser confundido com análise comercial publicada):

```powershell
$wwiLocalDb = 'C:\Program Files\Microsoft SQL Server\170\Tools\Binn\SqlLocalDB.exe'
& $wwiLocalDb start WWI_Portfolio
try {
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/query.ps1 -SqlFile consulta.local.sql -OutputFile consulta.local.json
    if ($LASTEXITCODE -ne 0) { throw 'Consulta falhou.' }
} finally {
    & $wwiLocalDb stop WWI_Portfolio
}
```

A interface retorna K01–K21 e contexto. Percentuais já estão em escala 0–100; NULL significa N/A. Filtros e parâmetros estão no [modelo da Etapa 4](modelo_etapa4.md#interface-dos-kpis). Consultas são seriais; não aumente paralelismo para compensar pressão de memória.
