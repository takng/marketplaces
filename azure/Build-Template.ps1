#requires -module Poshstache
param 
(
    [string] $TemplatePath,
    [string] $Parameters,
    [string] $ParametersFile,
    [string] $OutputFile
)

if (-not $Parameters) {
    $Parameters = Get-Content -Path $ParametersFile
}

(ConvertTo-PoshstacheTemplate -InputFile $TemplatePath -ParametersObject $Parameters) -replace '&amp;', '&' -replace '&#174;', '®' -replace '&#39;', '''' `
| Out-File $OutputFile -Force -Encoding "UTF8"