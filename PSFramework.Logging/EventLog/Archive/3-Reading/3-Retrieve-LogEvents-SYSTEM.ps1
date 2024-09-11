function Retrieve-LogEvents {
    <#
    .SYNOPSIS
    Retrieves the last 10 events from the event log stored in the registry.

    .DESCRIPTION
    The Retrieve-LogEvents function reads the log name from the registry and retrieves the last 10 events from that log.

    .EXAMPLE
    Retrieve-LogEvents
    Retrieves the last 10 events from the event log.
    #>

    [CmdletBinding()]
    param ()

    Begin {
        Write-EnhancedLog -Message "Starting Retrieve-LogEvents function" -Level "Notice"
    }

    Process {
        $logName = Get-LogNameFromRegistry

        if ($logName) {
            try {
                Write-Host "Attempting to retrieve the last 10 events from the log '$logName'."
                $events = Get-WinEvent -LogName $logName -MaxEvents 10
                
                if ($events.Count -gt 0) {
                    Write-Host "Successfully retrieved the last 10 events from the log '$logName'."
                    $events | Format-Table -AutoSize
                }
                else {
                    Write-Warning "No events found in the log '$logName'."
                }
            }
            catch {
                Write-EnhancedLog -Message "Failed to retrieve events from the log '$logName'. Error: $($_.Exception.Message)" -Level "ERROR"
                throw $_
            }
        }
        else {
            Write-Warning "Log name not found in the registry. Please ensure the user script has run and initialized the log."
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Retrieve-LogEvents function" -Level "Notice"
    }
}
