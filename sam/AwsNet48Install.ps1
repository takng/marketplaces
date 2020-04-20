$currentDirectory = Split-Path $script:MyInvocation.MyCommand.Path
Configuration AwsNet48Install
{
  param
   ()
    
   $installerUri = $currentDirectory + '\' + 'ndp48-web.exe'
    Import-DSCResource -Module PSDesiredStateConfiguration
    
    node "localhost"
    {

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        Script Install_Net_4.8
        {
            SetScript = {
                Write-Verbose "Starting configuration... installer uri $using:installerUri"
                
                $FileName = ($using:installerUri).Split('\')[-1]
                $BinPath = Join-Path  $env:SystemDrive -ChildPath "cfn\artifacts\$FileName"
                
                Write-Verbose "Installing .Net 4.8 from $BinPath"
                Write-Verbose "Executing $binpath /q /norestart"

                Start-Sleep 5
                Start-Process -FilePath $BinPath -ArgumentList "/q /norestart" -Wait -NoNewWindow            
                Start-Sleep 5

                Write-Verbose "Setting DSCMachineStatus to reboot server after DSC run is completed"

                $global:DSCMachineStatus = 1
            }

            TestScript = {
                [int]$NetBuildVersion = 528049

                if (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' | %{$_ -match 'Release'})
                {
                    [int]$CurrentRelease = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').Release
                    if ($CurrentRelease -lt $NetBuildVersion)
                    {
                        Write-Verbose "Current .Net build version is less than 4.8 ($CurrentRelease)"
                        return $false
                    }
                    else
                    {
                        Write-Verbose "Current .Net build version is the same as or higher than 4.8 ($CurrentRelease)"
                        return $true
                    }
                }
                else
                {
                    Write-Verbose ".Net build version not recognised"
                    return $false
                }
            }

            GetScript = {
                if (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' | %{$_ -match 'Release'})
                {
                    $NetBuildVersion =  (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').Release
                    return $NetBuildVersion
                }
                else
                {
                    Write-Verbose ".Net build version not recognised"
                    return ".Net 4.8 not found"
                }
            }
        }
    }
}
$outputPath = $currentDirectory + '\'
AwsNet48Install -OutputPath  $outputPath
Set-DscLocalConfigurationManager  -Path $outputPath -Verbose

Start-DscConfiguration -Force -Path $outputPath -Verbose -Wait
Get-DscLocalConfigurationManager