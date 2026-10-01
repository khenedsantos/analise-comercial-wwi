param([ValidateSet('Build','Validate','Inspect')][string]$Mode='Validate')
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$localdb='C:\Program Files\Microsoft SQL Server\170\Tools\Binn\SqlLocalDB.exe'
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$out=Join-Path $root "data\metadata\stage4-$stamp.json"
if($Mode -eq 'Inspect'){$out=Join-Path $root "data\metadata\stage4-inspect-$stamp.json"}
$sets=[Collections.Generic.List[object]]::new()
$disk=[Collections.Generic.List[object]]::new()
$messages=[Collections.Generic.List[string]]::new()
$failure=$null
$connection=New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString='Server=(localdb)\WWI_Portfolio;Database=WWI_Portfolio_Diagnostic;Integrated Security=true;Connect Timeout=60;Application Name=WWI Stage4'
$connection.add_InfoMessage({param($sender,$event) $messages.Add($event.Message); Write-Host $event.Message})
function Test-ValidationResults($results){
 $checks=@($results | ForEach-Object {$_.Rows} | Where-Object {$_.ContractID})
 return ($checks.Count -gt 0 -and @($checks | Where-Object {$_.Passed -ne $true}).Count -eq 0)
}
function Check-Disk([string]$phase){
 $free=([IO.DriveInfo]::new('C:\')).AvailableFreeSpace
 $disk.Add(@{Phase=$phase;FreeBytes=$free;At=[DateTime]::UtcNow.ToString('o')})
 if($free -lt 2GB){throw "Disk below 2 GiB at $phase ($free bytes). Stop; no cleanup authorized."}
}
function Read-Sql([string]$sql,[string]$label){
 Check-Disk $label
 $cmd=$connection.CreateCommand(); $cmd.CommandTimeout=180; $cmd.CommandText=$sql
 $reader=$cmd.ExecuteReader()
 try {
  do {
   if($reader.FieldCount -eq 0){continue}
   $rows=[Collections.Generic.List[object]]::new()
   while($reader.Read()){
    $row=[ordered]@{}
    for($i=0;$i -lt $reader.FieldCount;$i++){
     $v=$reader.GetValue($i)
     if($v -is [DBNull]){$v=$null}
     elseif($v -is [DateTime]){$v=$v.ToString('o')}
     $row[$reader.GetName($i)]=$v
    }
    $rows.Add([pscustomobject]$row)
   }
   $sets.Add(@{Batch=$label;Rows=$rows.ToArray()})
  }while($reader.NextResult())
 }finally{$reader.Dispose();$cmd.Dispose()}
 Check-Disk "$label completed"
}
# Guard all pre-existing evidence and normative documents, not just the backup.
$protected=@(Get-ChildItem (Join-Path $root 'scripts') -File | Where-Object {$_.Name -ne 'run_stage4.ps1' -and $_.Name -ne 'verify_stage4.py'})
$protected+=@(Get-ChildItem (Join-Path $root 'reports') -File | Where-Object {$_.Name -ne 'modelo_etapa4.md' -and $_.Name -ne 'validacao_etapa4.md'})
$protected+=@(Get-ChildItem (Join-Path $root 'data\metadata') -File | Where-Object {$_.Name -notlike 'stage4-*'})
$before=@{}; foreach($f in $protected){$before[$f.FullName]=(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash}
try{
 Check-Disk 'before instance start'
 $backupHash=(Get-FileHash -LiteralPath (Join-Path $root 'data\raw\WideWorldImporters-Standard.bak') -Algorithm SHA256).Hash.ToLowerInvariant()
 if($backupHash -ne '066279a8cd28c8d85cbd8215ea71a5d672b420cfbc19756b635c27bd8027dada'){throw 'Backup hash differs from contract.'}
 & $localdb start WWI_Portfolio
 if($LASTEXITCODE -ne 0){throw 'LocalDB start failed.'}
 $connection.Open()
 Read-Sql "SELECT name,type_desc,size/128.0 allocated_mb,FILEPROPERTY(name,'SpaceUsed')/128.0 used_mb FROM sys.database_files; SELECT name,value_in_use FROM sys.configurations WHERE name IN('max degree of parallelism','max server memory (MB)');" 'environment before'
 $files=@('sql\03_validation.sql')
 if($Mode -eq 'Build'){$files=@('sql\01_model.sql','sql\02_metrics.sql')+$files}
 if($Mode -eq 'Inspect'){$files=@()}
 foreach($file in $files){
  Write-Output "Running $file serially"
  $sql=[IO.File]::ReadAllText((Join-Path $root $file))
  $index=0
  foreach($batch in [regex]::Split($sql,'(?im)^GO\s*\r?$')){
   if(-not [string]::IsNullOrWhiteSpace($batch)){$index++; Write-Output "Batch $index"; Read-Sql $batch "$file batch $index"}
  }
 }
 Read-Sql "SELECT name,type_desc,size/128.0 allocated_mb,FILEPROPERTY(name,'SpaceUsed')/128.0 used_mb FROM sys.database_files; SELECT t.name,SUM(p.rows) rows FROM sys.tables t JOIN sys.partitions p ON p.object_id=t.object_id AND p.index_id IN(0,1) WHERE t.schema_id=SCHEMA_ID('analytics') GROUP BY t.name ORDER BY t.name;" 'environment after'
 if($Mode -eq 'Inspect'){
  Read-Sql "SELECT o.name,m.definition FROM sys.sql_modules m JOIN sys.objects o ON o.object_id=m.object_id WHERE o.schema_id=SCHEMA_ID('analytics') ORDER BY o.name; SELECT name,is_disabled,is_not_trusted FROM sys.foreign_keys WHERE schema_id=SCHEMA_ID('analytics');" 'existing modules and FK state'
 }elseif(-not (Test-ValidationResults $sets.ToArray())){throw 'Validation has failed assertions or no executed assertions. See saved evidence.'}
}catch{
 $failure=$_.Exception.Message
 Write-Warning $failure
}finally{
 $connection.Dispose()
 & $localdb stop WWI_Portfolio
 $stopExit=$LASTEXITCODE
 $state=(& $localdb info WWI_Portfolio | Out-String)
 $unchanged=$true
 foreach($path in $before.Keys){if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $before[$path]){$unchanged=$false}}
 $disk.Add(@{Phase='after normal stop';FreeBytes=([IO.DriveInfo]::new('C:\')).AvailableFreeSpace;At=[DateTime]::UtcNow.ToString('o')})
 $result=[ordered]@{Mode=$Mode;Failure=$failure;BackupSHA256=$backupHash;ProtectedFilesUnchanged=$unchanged;ProtectedFileCount=$before.Count;ProtectedSHA256=$before;StopExitCode=$stopExit;InstanceState=$state;Disk=$disk.ToArray();Results=$sets.ToArray();Messages=$messages.ToArray()}
 $result | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $out -Encoding UTF8
 Write-Output "Evidence: $out"
}
if($failure -or -not $unchanged -or $stopExit -ne 0){exit 1}
