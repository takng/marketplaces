param
(
	[hashtable] $templateParameters
)

Start-Transcript -Path C:\cfn\configuration.Log

$currentDirectory = Split-Path $script:MyInvocation.MyCommand.Path
$configfilePath = $currentDirectory + '\' + 'standard.xml'


$xml = New-Object XML
$xml.Load($configfilePath)
$ntaproduct = $templateParameters['ntaproduct']
$olmproduct = $templateParameters['olmproduct']
$plugins = $xml.SilentConfig.AppendChild($xml.CreateElement("Plugins"))
   # Below code add xml tag in silent config for holding OLM database details.
  if(![string]::IsNullOrEmpty($olmproduct)) {
    write-host "Adding OLM related tags [ OrionLogConfiguration, StorageConfig, CreateNewDatabase, DatabaseName, ServerName, UseSQLSecurity,User, UserPassword, AccountType, Account, AccountPassword] in silent config "; [datetime]::Now
    $olmDatabaseNode = $xml.SilentConfig.Host.Info.AppendChild($xml.CreateElement("OrionLogConfiguration"));
    $OlmStorage = $olmDatabaseNode.AppendChild($xml.CreateElement("StorageConfig"));
    $olmCreateNewDatabaseNode = $OlmStorage.AppendChild($xml.CreateElement("CreateNewDatabase"));
    $OlmStorage.AppendChild($xml.CreateElement("DatabaseName"));
    $OlmStorage.AppendChild($xml.CreateElement("ServerName"));
    $OlmStorage.AppendChild($xml.CreateElement("UseSQLSecurity"));
    $OlmStorage.AppendChild($xml.CreateElement("User"));
    $OlmStorage.AppendChild($xml.CreateElement("UserPassword"));
    $OlmStorage.AppendChild($xml.CreateElement("AccountType"));
    $OlmStorage.AppendChild($xml.CreateElement("Account"));
    $OlmStorage.AppendChild($xml.CreateElement("AccountPassword"));
    $plugin = $plugins.AppendChild($xml.CreateElement("Plugin"))
    $plugin.SetAttribute("FactoryType","SolarWinds.ConfigurationWizard.Plugin.LogMgmt.SilentConfigureFactory");
    $plugin.SetAttribute("Assembly","SolarWinds.ConfigurationWizard.Plugin.LogMgmt");
    }

      # Below code add xml tag in silent config for holding NTA database details.
  if(![string]::IsNullOrEmpty($ntaproduct)) {
    write-host "Adding NTA related tags [ OrionLogConfiguration, StorageConfig, CreateNewDatabase, DatabaseName, ServerName, UseSQLSecurity,User, UserPassword, AccountType, Account, AccountPassword] in silent config "; [datetime]::Now
    $ntaDatabaseNode = $xml.SilentConfig.Host.Info.AppendChild($xml.CreateElement("NetFlowConfiguration"));
    $ntaflowStorage = $ntaDatabaseNode.AppendChild($xml.CreateElement("FlowStorageConfig"));
    $olmCreateNewDatabaseNode = $ntaflowStorage.AppendChild($xml.CreateElement("CreateNewDatabase"));
    $ntaflowStorage.AppendChild($xml.CreateElement("DatabaseName"));
    $ntaflowStorage.AppendChild($xml.CreateElement("ServerName"));
    $ntaflowStorage.AppendChild($xml.CreateElement("UseSQLSecurity"));
    $ntaflowStorage.AppendChild($xml.CreateElement("User"));
    $ntaflowStorage.AppendChild($xml.CreateElement("UserPassword"));
    $ntaflowStorage.AppendChild($xml.CreateElement("AccountType"));
    $ntaflowStorage.AppendChild($xml.CreateElement("Account"));
    $ntaflowStorage.AppendChild($xml.CreateElement("AccountPassword"));
    $plugin = $plugins.AppendChild($xml.CreateElement("Plugin"))
    $plugin.SetAttribute("FactoryType","SolarWinds.ConfigurationWizard.Plugin.NetFlow.SilentMode.NetFlowSilentConfigureFactory");
    $plugin.SetAttribute("Assembly","SolarWinds.ConfigurationWizard.Plugin.NetFlow");
    }

#Update Orion specific database details
if($xml.SilentConfig.Host.Info.Database)
{
	write-host "Updating Orion database section"; [datetime]::Now
    $dbnode = $xml.SilentConfig.Host.Info.Database	
    $dbnode.ServerName = 'tcp:'+$templateParameters['dbServerName']
    $dbnode.DatabaseName = $templateParameters['databaseName']
    $dbnode.User = $templateParameters['dbUserName']
    $dbnode.UserPassword = $templateParameters['dbPassword']
    $dbnode.AccountPassword = $templateParameters['dbPassword']
}

#Update OLM specific database details
if ($xml.SilentConfig.Host.Info.OrionLogConfiguration.StorageConfig -and (![string]::IsNullOrEmpty($olmproduct))) {
	write-host "Updating OLM database section"; [datetime]::Now
    $nodeStorageConfig = $xml.SilentConfig.Host.Info.OrionLogConfiguration.StorageConfig
    $nodeStorageConfig.ServerName = 'tcp:'+$templateParameters['dbServerName']
    $nodeStorageConfig.DatabaseName = -join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_}) + 'olmDB'
    $nodeStorageConfig.User = $templateParameters['dbUserName']
    $nodeStorageConfig.UserPassword = $templateParameters['dbPassword']
    $nodeStorageConfig.AccountType = 'NewSql'
    $nodeStorageConfig.Account = 'SolarWindsOLMDBUser'
    $nodeStorageConfig.CreateNewDatabase = 'true'
    $nodeStorageConfig.UseSQLSecurity = 'true'
    $nodeStorageConfig.AccountPassword = $templateParameters['dbPassword']
	write-host "OLM Database Name "  $nodeStorageConfig.DatabaseName
}

#Update NTA specific database details
if ($xml.SilentConfig.Host.Info.NetFlowConfiguration.FlowStorageConfig -and (![string]::IsNullOrEmpty($ntaproduct))) {
	write-host "Updating NTA database section"; [datetime]::Now
    $nodeStorageConfig = $xml.SilentConfig.Host.Info.NetFlowConfiguration.FlowStorageConfig
    $nodeStorageConfig.ServerName = 'tcp:'+$templateParameters['dbServerName']
    $nodeStorageConfig.DatabaseName = -join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_}) + 'ntaDB'
    $nodeStorageConfig.User = $templateParameters['dbUserName']
    $nodeStorageConfig.UserPassword = $templateParameters['dbPassword']
    $nodeStorageConfig.AccountType = 'NewSql'
    $nodeStorageConfig.Account = 'SolarWindsNtaDatabaseUser'
    $nodeStorageConfig.CreateNewDatabase = 'true'
    $nodeStorageConfig.UseSQLSecurity = 'true'
    $nodeStorageConfig.AccountPassword = $templateParameters['dbPassword']
	write-host "NTA Database Name "  $nodeStorageConfig.DatabaseName
}

if($xml.SilentConfig.Host.Info.Website)
{
    $nodeWebsite = $xml.SilentConfig.Host.Info.Website
	$nodeWebsite.DefaultAdminPassword = $templateParameters['appUserPassword']
    $nodeWebsite.CertificateResolvableCN = $Env:COMPUTERNAME
}
if($xml.SilentConfig.InstallerConfiguration)
{
    $list = New-Object Collections.Generic.List[String]
    $node = $xml.SilentConfig.InstallerConfiguration
	$eocproduct = $templateParameters['eocproduct']
    $samproduct = $templateParameters['samproduct']
    $ipamproduct = $templateParameters['ipamproduct']
    $ncmproduct = $templateParameters['ncmproduct']
    $npmproduct = $templateParameters['npmproduct']
    $scmproduct = $templateParameters['scmproduct']
    $udtproduct = $templateParameters['udtproduct']
    $vmanproduct = $templateParameters['vmanproduct']
    $vnqmproduct = $templateParameters['vnqmproduct']
    $srmproduct = $templateParameters['srmproduct']
    $wpmproduct = $templateParameters['wpmproduct']
    $ntaproduct = $templateParameters['ntaproduct']
    $olmproduct = $templateParameters['olmproduct']
	
	if(![string]::IsNullOrEmpty($eocproduct)){
    $list.Add($eocproduct)
    }

    if(![string]::IsNullOrEmpty($samproduct)){
    $list.Add($samproduct)
    }
    if(![string]::IsNullOrEmpty($ipamproduct)){
    $list.Add($ipamproduct)
    }
     if(![string]::IsNullOrEmpty($ncmproduct)){
    $list.Add($ncmproduct)
    }
    if(![string]::IsNullOrEmpty($npmproduct)){
    $list.Add($npmproduct)
    }
    if(![string]::IsNullOrEmpty($scmproduct)){
    $list.Add($scmproduct)
    }
    if(![string]::IsNullOrEmpty($udtproduct)){
    $list.Add($udtproduct)
    }
    
    if(![string]::IsNullOrEmpty($vmanproduct)){
    $list.Add($vmanproduct)
    }
    if(![string]::IsNullOrEmpty($vnqmproduct)){
    $list.Add($vnqmproduct)
    }
    if(![string]::IsNullOrEmpty($srmproduct)){
    $list.Add($srmproduct)
    }
    if(![string]::IsNullOrEmpty($wpmproduct)){
    $list.Add($wpmproduct)
    }
    if(![string]::IsNullOrEmpty($ntaproduct)){
    $list.Add($ntaproduct)
    }
    if(![string]::IsNullOrEmpty($olmproduct)){
    $list.Add($olmproduct)
    }
    $productsList= ($list) -join ","
    Write-Host 'Products to install list : ' $productsList
    $node.ProductsToInstall = $productsList

}
Start-Sleep 5
$xml.Save($configfilePath)
write-host 'Configuration file updated....'; [datetime]::Now
write-host 'Creating CheckHealthScript Task ....'; [datetime]::Now
#Creating new User with user name 'orionadmin' through which schedular task will be created and run using that user.
net user 'orionadmin' 'Passw0rd' /add /comment:"orion  installer" /fullname:"Orion Admin" /passwordchg:NO
#Adding the new user to the 'Administrators' group
net localgroup Administrators /add 'orionadmin'
Write-Host 'User (orionadmin) Added to Administrators'
$stackName = $templateParameters['awsStackName']
$stackRegion = $templateParameters['awsStackRegion']
$scheduledTime = (Get-Date).AddMinutes(1).ToString("HH:mm")

schtasks /CREATE /TN CheckHealthScript /TR "powershell.exe -ExecutionPolicy Unrestricted  -file 'C:\cfn\artifacts\solarwindInstaller.ps1' $stackName $stackRegion" /RL HIGHEST /SC ONCE /ST $scheduledTime /RU 'orionadmin' /RP 'Passw0rd'

write-host 'Created CheckHealthScript Task ....'; [datetime]::Now
Stop-Transcript