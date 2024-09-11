function Remove-ModernEventLog {
    param (
        [string]$LogName
    )

    # Disable and clear the event log using wevtutil
    try {
        Write-Host "Disabling the log '$LogName'..."
        wevtutil sl $LogName /e:false
        Write-Host "Clearing the log '$LogName'..."
        wevtutil cl $LogName
    } catch {
        Write-Warning "Failed to disable or clear the log '$LogName'. Error: $_"
    }

    # Remove the log file
    $logFilePath = "C:\Windows\System32\winevt\Logs\$LogName.evtx"
    if (Test-Path $logFilePath) {
        try {
            Remove-Item -Path $logFilePath -Force
            Write-Host "Log file '$logFilePath' deleted."
        } catch {
            Write-Warning "Failed to delete the log file '$logFilePath'. It might be in use by another process."
        }
    } else {
        Write-Host "Log file '$logFilePath' does not exist."
    }

    Write-Host "You may need to restart the system or the Windows Event Log service to complete the cleanup."
}

# Example usage
Remove-ModernEventLog -LogName "MyCompany"
