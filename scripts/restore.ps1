$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$backup = Join-Path $root 'data\raw\WideWorldImporters-Standard.bak'
if ((Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash -ne '066279A8CD28C8D85CBD8215EA71A5D672B420CFBC19756B635C27BD8027DADA') { throw 'Unexpected backup SHA-256' }
$drive = New-Object IO.DriveInfo ([IO.Path]::GetPathRoot($root))
$allocation = 1073741824L + 2147483648L + 104857600L
if ($drive.AvailableFreeSpace - $allocation -lt 2GB) { throw 'Restore refused: less than 2 GiB safety reserve after allocation.' }
New-Item -ItemType Directory -Force (Join-Path $root 'data\sqlserver') | Out-Null
& (Join-Path $PSScriptRoot 'query.ps1') -SqlFile (Join-Path $PSScriptRoot 'restore.sql') -Database master -OutputFile (Join-Path $root 'data\metadata\restore.json')
