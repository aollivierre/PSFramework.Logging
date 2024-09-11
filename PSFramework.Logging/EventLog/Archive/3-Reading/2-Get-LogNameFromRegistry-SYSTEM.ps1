function Get-LogNameFromRegistry {
    <#
    .SYNOPSIS
    Retrieves the event log name stored in the registry.

    .DESCRIPTION
    The Get-LogNameFromRegistry function reads the event log name from a registry key, making it accessible for scripts running in both USER and SYSTEM contexts.

    .EXAMPLE
    $logName = Get-LogNameFromRegistry
    Retrieves the log name from the registry.
    #>

    [CmdletBinding()]
    param ()

    Begin {
        Write-EnhancedLog -Message "Starting Get-LogNameFromRegistry function" -Level "Notice"
    }

    Process {
        try {
            $regPath = "HKLM:\SOFTWARE\MyApp\Logging"

            if (Test-Path -Path $regPath) {
                $logName = Get-ItemProperty -Path $regPath -Name "LogName" -ErrorAction Stop
                Write-EnhancedLog -Message "Retrieved log name '$($logName.LogName)' from registry." -Level "INFO"
                return $logName.LogName
            }
            else {
                Write-EnhancedLog -Message "Registry path '$regPath' not found." -Level "WARNING"
                return $null
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Get-LogNameFromRegistry function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Get-LogNameFromRegistry function" -Level "Notice"
    }
}



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
