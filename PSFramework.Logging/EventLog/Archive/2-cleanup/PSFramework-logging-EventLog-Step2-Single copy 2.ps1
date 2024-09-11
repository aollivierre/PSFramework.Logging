function Remove-EventLogAndSource {
    param (
        [string]$LogName,
        [string]$EventSource
    )

    # Validate parameters
    if (-not $LogName) {
        Write-Warning "LogName is required."
        return
    }
    if (-not $EventSource) {
        Write-Warning "EventSource is required."
        return
    }

    # Remove the event source if it exists
    if ([System.Diagnostics.EventLog]::SourceExists($EventSource)) {
        [System.Diagnostics.EventLog]::DeleteEventSource($EventSource)
        Write-Host "Event source '$EventSource' deleted." -ForegroundColor Green
    } else {
        Write-Host "Event source '$EventSource' does not exist." -ForegroundColor Yellow
    }

    # Remove the event log
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        Remove-EventLog -LogName $LogName -ErrorAction SilentlyContinue
    } else {
        # Use .NET to remove the log for newer versions if necessary
        $log = [System.Diagnostics.EventLog]::GetEventLogs() | Where-Object { $_.Log == $LogName }
        if ($log) {
            [System.Diagnostics.EventLog]::Delete($LogName)
            Write-Host "Event log '$LogName' deleted." -ForegroundColor Green
        } else {
            Write-Host "Event log '$LogName' does not exist." -ForegroundColor Yellow
        }
    }

    # Clean up the log file if exists
    $logFilePath = "C:\Windows\System32\winevt\Logs\$LogName.evtx"
    if (Test-Path $logFilePath) {
        Remove-Item -Path $logFilePath -Force
        Write-Host "Log file '$logFilePath' deleted." -ForegroundColor Green
    } else {
        Write-Host "Log file '$logFilePath' does not exist." -ForegroundColor Yellow
    }
}

# Example usage
Remove-EventLogAndSource -LogName "MyCompany" -EventSource "MyCompanySource"
