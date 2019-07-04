param
(
	[string]$silentConfigUri,
	[string]$installerUri,
	[string]$dbServerName, 
	[string]$databaseName, 
	[string]$dbUserName, 
	[string]$dbPassword,
	[string]$appUserPassword,
	[string]$vmName
)

Start-Transcript -Path C:\postinstall.Log

#download the silent installer config file from Artifacts
write-host "downloading silent installer config file from $silentConfigUri"; [datetime]::Now
$configfilePath = "C:\Windows\Temp\silentconfig.xml"
Invoke-WebRequest $silentConfigUri -OutFile $configfilePath
write-host "download completed: $configfilePath"; [datetime]::Now

#download the installer from Artifacts
write-host "downloading installer from $installerUri"; [datetime]::Now
$installer_name  = "Solarwinds-Orion-SAM.exe"
Invoke-WebRequest $installerUri -OutFile "C:\Windows\Temp\$installer_name"
write-host "download completed: $installerfilePath"; [datetime]::Now

#update DB details
$xml=New-Object XML
$xml.Load($configfilePath)

$node=$xml.SilentConfig.InstallerConfiguration
$node.WebConsolePassword=$appUserPassword

if($xml.SilentConfig.Host.Info.Database)
{
	$dbnode=$xml.SilentConfig.Host.Info.Database	
	$dbnode.ServerName=$dbServerName
	$dbnode.DatabaseName=$databaseName
	$dbnode.User=$dbUserName    
	$dbnode.UserPassword=$dbPassword
	$dbnode.AccountPassword=$dbPassword
}
if($xml.SilentConfig.Host.Info.Website)
{
	$nodeWebsite = $xml.SilentConfig.Host.Info.Website
	$nodeWebsite.CertificateResolvableCN = $vmName
}

$xml.Save($configfilePath)

#create installer file
New-Item C:\Windows\Temp\installer.ps1 -ItemType file
Add-Content 'C:\Windows\Temp\installer.ps1' .\$installer_name" /s /ConfigFile=""$configfilePath"" /AutoUpdate=false"

#Start installation
write-host ' starting installation solarwindinstaller....'; [datetime]::Now
Set-Location "C:\Windows\Temp"
.\installer.ps1
write-host ' installation started solarwindinstaller....'; [datetime]::Now

#check for if installation status
$process_name = $installer_name.Substring(0,$installer_name.LastIndexOf('.'))
while(1)
{
	$Solarwinds = Get-Process $process_name -ErrorAction SilentlyContinue
	if ($Solarwinds) {
		Start-Sleep 5
		Remove-Variable Solarwinds
		continue;
	}
	else {
		write-host "process completed"; [datetime]::Now
		Remove-Variable Solarwinds
		break;
	}
}

#delete files created in installation process
write-host ' Deleting the files created in installation process'; [datetime]::Now

$installer_file = "C:\Windows\Temp\installer.ps1"
if (Test-Path $installer_file) 
{
	Remove-Item $installer_file
	write-host 'silent installer file deleted'; [datetime]::Now
}

write-host 'Files deleted which has been created in installation process'; [datetime]::Now 

Stop-Transcript