Import-Module C:\code\Modulesv2-BETA\EnhancedLoggingAO\EnhancedLoggingAO.psm1 -Force:$true -Verbose:$false

# Set-PSFConfig -Fullname 'PSFramework.Logging.FileSystem.ModernLog' -Value $true


# $logFilePath = ""
# # $logFilePath = "C:\Logs\YourLogFile.log"

# if (Test-Path -Path $logFilePath) {
#     Get-Content -Path $logFilePath | ConvertFrom-Csv | Format-Table -AutoSize
# } else {
#     Write-Host "Log file not found: $logFilePath" -ForegroundColor Red
# }


$logFilePath = "C:\Users\Admin-Abdullah\AppData\Roaming\PowerShell\PSFramework\Logs\DESKTOP-9KHVRUI_5684_message_0.log"

if (Test-Path -Path $logFilePath) {
    # Read the CSV log file
    $logEntries = Import-Csv -Path $logFilePath

    # Display the log entries in a table format
    $logEntries | Format-Table -AutoSize
} else {
    Write-Host "Log file not found: $logFilePath" -ForegroundColor Red
}
