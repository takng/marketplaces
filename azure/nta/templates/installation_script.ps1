param
(
	[string]$silentConfigUri,
	[string]$dbServerName, 
	[string]$databaseName, 
	[string]$dbUserName, 
	[string]$dbPassword,
	[string]$ntaServerName, 
	[string]$ntaDatabaseName, 
	[string]$ntaUserName, 
	[string]$ntaPassword
)

Start-Transcript -Path C:\postinstall.Log

write-host "downloading silent installer config file from $silentConfigUri"; [datetime]::Now
$filePath = "C:\Windows\Temp\silentconfig.xml"
Invoke-WebRequest $silentConfigUri -OutFile $filePath
write-host "download completed: $filePath"; [datetime]::Now

$installer_path = "https://downloads.solarwinds.com/solarwinds/OnlineInstallers/RTM/NTA/Solarwinds-Orion-NTA.exe"

write-host "downloading solarwind online installer from $installer_path"; [datetime]::Now
$installer_name  = "Solarwinds-Orion-NTA.exe"
Invoke-WebRequest $installer_path -OutFile "C:\Windows\Temp\$installer_name"
write-host "download completed: C:\Windows\Temp\$installer_name"; [datetime]::Now

$xml=New-Object XML
$xml.Load($filePath)

if($xml.SilentConfig.Host.Info.Database)
{
	$oriondbnode=$xml.SilentConfig.Host.Info.Database	
	$oriondbnode.ServerName=$dbServerName+$oriondbnode.ServerName
	$oriondbnode.DatabaseName=$databaseName
	$oriondbnode.User=$dbUserName    
	$oriondbnode.UserPassword=$dbPassword
	$oriondbnode.AccountPassword=$dbPassword

	$ntadbnode=$xml.SilentConfig.Host.Info.NetFlowConfiguration.FlowStorageConfig
	$ntadbnode.ServerName=$ntaServerName+$ntadbnode.ServerName
	$ntadbnode.DatabaseName=$ntaDatabaseName
	$ntadbnode.User=$ntaUserName    
	$ntadbnode.UserPassword=$ntaPassword
	$ntadbnode.AccountPassword=$ntaPassword
	
	$xml.Save($filePath)
}

New-Item C:\Windows\Temp\installer.ps1 -ItemType file
Add-Content 'C:\Windows\Temp\installer.ps1' .\$installer_name" /s /ConfigFile=""$filePath"""

write-host ' starting installation solarwindinstaller....'; [datetime]::Now
cd "C:\Windows\Temp"
.\installer.ps1
write-host ' installation started solarwindinstaller....'; [datetime]::Now

$process_name = $installer_name.Substring(0,$installer_name.LastIndexOf('.'))
while(1)
{
	$Solarwinds = Get-Process $process_name -ErrorAction SilentlyContinue
	if ($Solarwinds) {
		Sleep 5
		Remove-Variable Solarwinds
		continue;
	}
	else {
		write-host "process completed"; [datetime]::Now
		Remove-Variable Solarwinds
		break;
	}
}

write-host ' Deleting the files created in installation process'; [datetime]::Now

$installer_file = "C:\Windows\Temp\installer.ps1"
if (Test-Path $installer_file) 
{
	Remove-Item $installer_file
	write-host 'silent installer file deleted'; [datetime]::Now
}

write-host 'Files deleted which has been created in installation process'; [datetime]::Now 

Stop-Transcript