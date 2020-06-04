param
(
    $stackName,
    $stackRegion,
    $installerParameter
)
Start-Transcript -Path C:\cfn\SolarwindInstallationStatusLog.Log

$InstallerName = 'SolarWinds.Orion.Installer'
$Exclusions = @('C:\Inetpub\SolarWinds',
    'C:\ProgramData\SolarWinds',
    'C:\Program Files (x86)\Common Files\SolarWinds'
    'C:\Program Files (x86)\SolarWinds',
    'C:\Windows\Temp\SolarWinds',
    'C:\Windows\Temp\JET*.tmp')
Write-Host "Adding Windows Defender exclusions for SolarWinds Orion"

foreach ($Exclusion in $Exclusions) {
    Add-MpPreference -ExclusionPath $Exclusion
}

$arguments = @{
    FilePath = "C:\cfn\artifacts\$InstallerName.exe"
    ArgumentList = '/s', '/ConfigFile="C:\cfn\artifacts\standard.xml"'
}
if ($installerParameter) {
    $arguments["ArgumentList"] += $installerParameter
}
Start-Process @arguments

Start-Sleep 5
$StartTime = $(get-date)
$elapsedTime

$website = 'SolarWinds NetPerfMon'
$webAppPool = 'SolarWinds Orion Application Pool' 
$jobName = "swisvcstop"
$timeout = 300 * 1000

function Get-SolarWindsServices() {
    Get-service | Where-Object { ($_.Name -like 'SolarWinds*') -Or ($_.DisplayName -like '*SolarWinds*') }    
}

function Stop-SolarWindsServices() { 
    Get-SolarWindsServices | ForEach-Object {
        Write-Host "Stopping $($_.Name)"
        Start-Job -Name $jobName -Scriptblock { Stop-Service -Name $args[0] } -ArgumentList $_.Name
    }

    Start-Job -Name $jobName -ArgumentList $website, $timeout -Scriptblock {
        Stop-Website $args[0]
        $timeout = $args[1]
        $time = 0
        $wait = 200
        while (($time -lt $timeout) -and (Get-WebsiteState -Name $args[0]).Value -ne "Stopped") {
            Start-Sleep -Milliseconds $wait
            $time += $wait
        }
    }

    Start-Job -Name $jobName -ArgumentList $webAppPool, $timeout -Scriptblock {
        Stop-WebAppPool $args[0]
        $timeout = $args[1]
        $time = 0
        $wait = 200
        while (($time -lt $timeout) -and (Get-WebAppPoolState -Name $args[0]).Value -ne "Stopped") {
            Start-Sleep -Milliseconds $wait
            $time += $wait
        }
    }

    $batch = Get-Job -Name $jobName
    Write-Host "Waiting for all services to be stopped..."
    $batch | Wait-Job
    $batch | Remove-Job
}

function Start-SolarWindsServices() { 
    Write-Host "Starting services..."
    Get-SolarWindsServices | ForEach-Object { Write-Output "Starting $($_.Name)..."; Start-Service $_ }
    Start-Website $website
    Start-WebAppPool $webAppPool
}

write-host "AWS Region " $stackRegion
write-host "AWS Stack " $stackName
while (1) {
    $swInstallationStatus = Get-Process $InstallerName -ErrorAction SilentlyContinue
   
    if ($swInstallationStatus) {
        Start-Sleep 5
        Remove-Variable swInstallationStatus
        $elapsedTime = $(get-date) - $StartTime
        $totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
        write-host "Time elapsed since installation start : " ; $totalTime
        write-host "Orion installation in progress .... "; [datetime]::Now
        continue;
    }
    else {
        write-host "Installation completed in : " ; $totalTime	
        Write-Host "Stopping SolarWinds services..."
        # Stopping SolarWinds services [Spinning issue]
        Stop-SolarWindsServices
        # Starting SolarWinds services
        Start-SolarWindsServices
        Write-Host "SolarWinds services restarted..."
        write-host "Sending signal for completion...... "
        cfn-signal.exe --resource EC2Instance --stack $stackName --region $stackRegion
        write-host "Signal sent successsfully."
        Remove-Variable swInstallationStatus
        break;
    }
}
Stop-Transcript