# Define an array of log name patterns to search for
$logPatterns = @("PSFramework", "AppLog", "PSF")

# Retrieve all logs that match any of the patterns
$logsToRemove = Get-WinEvent -ListLog * | Where-Object {
    $_.LogName -match ($logPatterns -join "|")
}

# Stop the Windows Event Log service before starting the cleanup
Write-Host "Stopping the Windows Event Log service..."
Stop-Service -Name "EventLog" -Force
Start-Sleep -Seconds 5

# Loop through the logs and remove them
foreach ($log in $logsToRemove) {
    $logName = $log.LogName
    $folderPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\$logName"
    $logPath = "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\$logName"
    $logFilePath = "C:\Windows\System32\winevt\Logs\$logName.evtx"

    # Unregister the event source if it exists
    if ([System.Diagnostics.EventLog]::SourceExists($logName)) {
        [System.Diagnostics.EventLog]::DeleteEventSource($logName)
        Write-Host "Event source '$logName' deleted."
    } else {
        Write-Host "Event source '$logName' does not exist."
    }

    # Delete the custom log registry key
    if (Test-Path $logPath) {
        Remove-Item -Path $logPath -Recurse -Force
        Write-Host "Custom log '$logPath' deleted."
    } else {
        Write-Host "Custom log '$logPath' does not exist."
    }

    # Delete the custom folder (channel) registry key
    if (Test-Path $folderPath) {
        Remove-Item -Path $folderPath -Recurse -Force
        Write-Host "Custom folder (channel) '$folderPath' deleted."
    } else {
        Write-Host "Custom folder (channel) '$folderPath' does not exist."
    }

    # Delete the actual log file
    if (Test-Path $logFilePath) {
        Remove-Item -Path $logFilePath -Force
        Write-Host "Log file '$logFilePath' deleted."
    } else {
        Write-Host "Log file '$logFilePath' does not exist."
    }

    Write-Host "Cleanup for $logName completed.`n"
}

# Start the Windows Event Log service again after the entire loop
Write-Host "Starting the Windows Event Log service..."
Start-Service -Name "EventLog"

# Restart all key services related to event logs
$services = @('Winmgmt', 'MSDTC')
foreach ($service in $services) {
    Restart-Service -Name $service -Force
    Write-Host "$service restarted."
}

Write-Host "Log removal process complete. The Windows Event Log service has been restarted."
