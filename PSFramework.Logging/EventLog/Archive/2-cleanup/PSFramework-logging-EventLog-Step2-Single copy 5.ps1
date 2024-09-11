function Remove-ModernEventLog {
    param (
        [string]$LogName
    )

    # Stop the Windows Event Log service
    Write-Host "Stopping the Windows Event Log service..."
    Stop-Service -Name "EventLog" -Force

    # Wait briefly to ensure the service is fully stopped
    Start-Sleep -Seconds 5

    # Remove the log file
    $logFilePath = "C:\Windows\System32\winevt\Logs\$LogName.evtx"
    if (Test-Path $logFilePath) {
        try {
            Remove-Item -Path $logFilePath -Force
            Write-Host "Log file '$logFilePath' deleted."
        } catch {
            Write-Warning "Failed to delete the log file '$logFilePath'."
        }
    } else {
        Write-Host "Log file '$logFilePath' does not exist."
    }

    # Remove the registry key associated with the log
    $logRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\$LogName"
    if (Test-Path $logRegistryPath) {
        try {
            Remove-Item -Path $logRegistryPath -Recurse -Force
            Write-Host "Registry key '$logRegistryPath' deleted."
        } catch {
            Write-Warning "Failed to delete the registry key '$logRegistryPath'."
        }
    } else {
        Write-Host "Registry key '$logRegistryPath' does not exist."
    }

    # Start the Windows Event Log service again
    Write-Host "Starting the Windows Event Log service..."
    Start-Service -Name "EventLog"

    Write-Host "Log removal process complete. The Windows Event Log service has been restarted."
}

# Example usage
Remove-ModernEventLog -LogName "MyCompany"
