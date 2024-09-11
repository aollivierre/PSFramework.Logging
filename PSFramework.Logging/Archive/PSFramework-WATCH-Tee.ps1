Import-Module C:\code\Modulesv2-BETA\EnhancedLoggingAO\EnhancedLoggingAO.psm1 -Force:$true -Verbose:$false

$logFilePath = "C:\Users\Admin-Abdullah\AppData\Roaming\PowerShell\PSFramework\Logs\DESKTOP-9KHVRUI_9800_message_0.log"
# $logFilePath = "C:\Logs\YourLogFile.log"
$monitorPath = "C:\Logs\MonitoredLogs.txt"

if (Test-Path -Path $logFilePath) {
    Get-Content -Path $logFilePath -Wait | Tee-Object -FilePath $monitorPath | ForEach-Object {
        if ($_ -match "ERROR") {
            Write-Host $_ -ForegroundColor Red
        } elseif ($_ -match "WARNING") {
            Write-Host $_ -ForegroundColor Yellow
        } elseif ($_ -match "INFO") {
            Write-Host $_ -ForegroundColor Green
        } else {
            Write-Host $_
        }
    }
} else {
    Write-Host "Log file not found: $logFilePath" -ForegroundColor Red
}
