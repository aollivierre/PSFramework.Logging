# Define the path for the log in the registry
$logName = "MyCompany"
$logPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\$logName"
$logFilePath = "C:\Windows\System32\winevt\Logs\$logName.evtx"

# Unregister any event sources associated with this log
$eventSources = [System.Diagnostics.EventLog]::GetEventSources()
foreach ($source in $eventSources) {
    if ([System.Diagnostics.EventLog]::LogNameFromSourceName($source, $null) -eq $logName) {
        [System.Diagnostics.EventLog]::DeleteEventSource($source)
        Write-Host "Event source '$source' associated with log '$logName' deleted."
    }
}

# Delete the custom log registry key
if (Test-Path $logPath) {
    Remove-Item -Path $logPath -Recurse -Force
    Write-Host "Custom log '$logPath' deleted."
} else {
    Write-Host "Custom log '$logPath' does not exist."
}

# Delete the actual log file
if (Test-Path $logFilePath) {
    Remove-Item -Path $logFilePath -Force
    Write-Host "Log file '$logFilePath' deleted."
} else {
    Write-Host "Log file '$logFilePath' does not exist."
}

# Inform the user about restart requirement
Write-Host "You may need to restart the system or the Windows Event Log service to complete the cleanup."
