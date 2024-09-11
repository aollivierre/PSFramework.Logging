for ($i = 1; $i -le 5; $i++) {
    # Define the paths for the folder and log in the registry
    $folderName = "MyCompany$i"
    $logName = "MyCustomApp$i"
    $folderPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\$folderName"
    $logPath = "$folderPath\$logName"

    # Define the path to the actual log file
    $logFilePath = "C:\Windows\System32\winevt\Logs\$folderName-$logName.evtx"

    # Unregister the event source
    $sourceName = "MyScriptSource$i"
    if ([System.Diagnostics.EventLog]::SourceExists($sourceName)) {
        [System.Diagnostics.EventLog]::DeleteEventSource($sourceName)
        Write-Host "Event source '$sourceName' deleted."
    } else {
        Write-Host "Event source '$sourceName' does not exist."
    }

    # Delete the custom log registry key
    if (Test-Path $logPath) {
        Remove-Item -Path $logPath -Recurse -Force
        Write-Host "Custom log '$logPath' deleted."
    } else {
        Write-Host "Custom log '$logPath' does not exist."
    }

    # Delete the custom folder registry key if empty
    if (Test-Path $folderPath) {
        Remove-Item -Path $folderPath -Recurse -Force
        Write-Host "Custom folder '$folderPath' deleted."
    } else {
        Write-Host "Custom folder '$folderPath' does not exist."
    }

    # Delete the actual log file
    if (Test-Path $logFilePath) {
        Remove-Item -Path $logFilePath -Force
        Write-Host "Log file '$logFilePath' deleted."
    } else {
        Write-Host "Log file '$logFilePath' does not exist."
    }

    Write-Host "Cleanup for $folderName and $logName completed.`n"
}

# Inform the user about restart requirement
Write-Host "You may need to restart the system or the Windows Event Log service to complete the cleanup."
