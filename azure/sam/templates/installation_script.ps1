param
(
	[string]$typeOfInstallation,
	[string]$productsToInstall,
	[string]$dbServerName, 
	[string]$databaseName, 
	[string]$dbUserName, 
	[string]$dbPassword
)

Start-Transcript -Path C:\postinstall.Log

if($typeOfInstallation -eq "false" -OR $typeOfInstallation -eq "False" -OR $typeOfInstallation -eq "FALSE") {
	[bool]$isStandard = $false
}
else {
	[bool]$isStandard = $true
}

write-host ' installing NuGet module....'; [datetime]::Now
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
write-host ' installed NuGet module....'; [datetime]::Now

write-host ' installing azure module....'; [datetime]::Now
Install-Module -Name Azure,AzureRM -force
write-host ' installed azure module....'; [datetime]::Now

$s_name = "vinayblob1"
$pass = "MOSlYQq3cMy+ZsZtqUmaHBL3gZ2PQshjmyKimPLBupDYrq9EWnDcujXNY3XyPUUf3g/EcFLMPnZbdt4vGzZ5DA=="
$ctx = new-azurestoragecontext -StorageAccountName $s_name -StorageAccountKey $pass

write-host 'coping text file from azure blob....'; [datetime]::Now
if($isStandard)
{
	Get-AzureStorageBlobContent -Blob standard.xml -Container vinay-storage-account-container -Destination C:\Windows\Temp\ -Context $ctx
}
else
{
	Get-AzureStorageBlobContent -Blob express.xml -Container vinay-storage-account-container -Destination C:\Windows\Temp\ -Context $ctx	
}
write-host ' copied text file from azure blob....'; [datetime]::Now

write-host ' copying solarwindinstaller  from azure blob....'; [datetime]::Now
Get-AzureStorageBlobContent -Blob Solarwinds-Orion-NCM-8.0-Beta2-OfflineInstaller.exe  -Container vinay-storage-account-container -Destination C:\Windows\Temp\ -Context $ctx
write-host ' copied solarwindinstaller  from azure blob....'; [datetime]::Now

$filePath = 'C:\Windows\Temp\express.xml'
if($isStandard)
{
	$filePath = 'C:\Windows\Temp\standard.xml'
}

$xml=New-Object XML
$xml.Load($filePath)

$node=$xml.SilentConfig.InstallerConfiguration
$node.ProductsToInstall=$productsToInstall 

if($isStandard)
{
	$node=$xml.SilentConfig.Host.Info.Database	
	$node.ServerName=$dbServerName
	$node.DatabaseName=$databaseName
	$node.User=$dbUserName    
	$node.UserPassword=$dbPassword
}

$xml.Save($filePath)

cd "C:\Windows\Temp"
write-host ' starting installation solarwindinstaller....'; [datetime]::Now
if($isStandard)
{
	.\Solarwinds-Orion-NCM-8.0-Beta2-OfflineInstaller.exe /s /ConfigFile="C:\Windows\Temp\standard.xml"
}
else
{
	.\Solarwinds-Orion-NCM-8.0-Beta2-OfflineInstaller.exe /s /ConfigFile="C:\Windows\Temp\express.xml"
}
write-host ' installation started solarwindinstaller....'; [datetime]::Now

while(1)
{
	$Solarwinds = Get-Process Solarwinds-Orion-NCM-8.0-Beta2-OfflineInstaller -ErrorAction SilentlyContinue
	if ($Solarwinds) {
	  Sleep 5
	  Remove-Variable Solarwinds
	  continue;
	}
	else {
		write-host "installation completed"
		Remove-Variable Solarwinds
	    break;
	}
}

Stop-Transcript