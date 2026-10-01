param(
    [Parameter(Mandatory=$true)][string]$SqlFile,
    [string]$Database = 'WWI_Portfolio_Diagnostic',
    [Parameter(Mandatory=$true)][string]$OutputFile
)
$ErrorActionPreference = 'Stop'
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = "Server=(localdb)\WWI_Portfolio;Database=$Database;Integrated Security=true;Connect Timeout=60;Application Name=WWI Stage2 Audit"
$messages = New-Object System.Collections.Generic.List[string]
$connection.add_InfoMessage({param($sender,$event) $messages.Add($event.Message)})
try {
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandTimeout = 900
    $projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).Replace("'", "''")
    $command.CommandText = [IO.File]::ReadAllText((Resolve-Path $SqlFile)).Replace('{{PROJECT_ROOT_SQL}}', $projectRoot)
    $reader = $command.ExecuteReader()
    $sets = New-Object System.Collections.Generic.List[object]
    do {
        if ($reader.FieldCount -eq 0) { continue }
        $rows = New-Object System.Collections.Generic.List[object]
        while ($reader.Read()) {
            $row = [ordered]@{}
            for ($i=0; $i -lt $reader.FieldCount; $i++) {
                $value = $reader.GetValue($i)
                if ($value -is [DBNull]) { $value = $null }
                elseif ($value -is [DateTime]) { $value = $value.ToString('o') }
                elseif ($value -is [byte[]]) { $value = [Convert]::ToBase64String($value) }
                $row[$reader.GetName($i)] = $value
            }
            $rows.Add([pscustomobject]$row)
        }
        $sets.Add(@{rows=$rows.ToArray()})
    } while ($reader.NextResult())
    $reader.Close()
    $result = @{generated_at_utc=[DateTime]::UtcNow.ToString('o'); database=$Database; results=$sets.ToArray(); messages=$messages.ToArray()}
    $json = ConvertTo-Json -InputObject $result -Depth 30
    [IO.File]::WriteAllText([IO.Path]::GetFullPath($OutputFile), $json, (New-Object Text.UTF8Encoding($false)))
    Write-Output "Saved $OutputFile ($($sets.Count) result sets)"
} finally { $connection.Dispose() }
