$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
foreach ($name in @('inventory','audit','followup','exceptions','pricing_semantics','integrity')) {
    & (Join-Path $PSScriptRoot 'query.ps1') -SqlFile (Join-Path $PSScriptRoot ($name+'.sql')) -OutputFile (Join-Path $root ('data\metadata\'+$name+'.json'))
}
