Import-Module C:\code\Modulesv2-BETA\EnhancedLoggingAO\EnhancedLoggingAO.psm1 -Force:$true -Verbose:$false

$logFilePath = "C:\Users\Admin-Abdullah\AppData\Roaming\PowerShell\PSFramework\Logs\DESKTOP-9KHVRUI_9800_message_0.log"

if (Test-Path -Path $logFilePath) {
    # Read the logs and convert from CSV
    $logEntries = Get-Content -Path $logFilePath | ConvertFrom-Csv

    # Display the logs in the console with color coding
    $logEntries | ForEach-Object {
        if ($_.Level) {
            switch ($_.Level.ToUpper()) {
                "CRITICAL" {
                    Write-Host $_ -ForegroundColor Magenta
                }
                "ERROR" {
                    Write-Host $_ -ForegroundColor Red
                }
                "WARNING" {
                    Write-Host $_ -ForegroundColor Yellow
                }
                "INFO" {
                    Write-Host $_ -ForegroundColor Green
                }
                "DEBUG" {
                    Write-Host $_ -ForegroundColor Cyan
                }
                default {
                    Write-Host $_ -ForegroundColor White
                }
            }
        } else {
            Write-Host "Log entry missing Level: $_" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "Log file not found: $logFilePath" -ForegroundColor Red
}
