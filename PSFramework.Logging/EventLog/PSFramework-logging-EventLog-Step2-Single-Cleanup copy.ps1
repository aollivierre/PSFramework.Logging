# Install the PSFramework module if not already installed
# Install-Module -Name PSFramework -Scope CurrentUser -Force -AllowClobber

#region FIRING UP MODULE STARTER
#################################################################################################
#                                                                                               #
#                                 FIRING UP MODULE STARTER                                      #
#                                                                                               #
#################################################################################################

# Fetch the script content
$scriptContent = Invoke-RestMethod "https://raw.githubusercontent.com/aollivierre/module-starter/main/Module-Starter.ps1"

# Define replacements in a hashtable
$replacements = @{
    '\$Mode = "dev"'                     = '$Mode = "dev"'
    '\$SkipPSGalleryModules = \$false'   = '$SkipPSGalleryModules = $true'
    '\$SkipCheckandElevate = \$false'    = '$SkipCheckandElevate = $true'
    '\$SkipAdminCheck = \$false'         = '$SkipAdminCheck = $true'
    '\$SkipPowerShell7Install = \$false' = '$SkipPowerShell7Install = $true'
    '\$SkipModuleDownload = \$false'     = '$SkipModuleDownload = $true'
    '\$SkipGitRepos = \$false'           = '$SkipGitRepos = $true'
}

# Apply the replacements
foreach ($pattern in $replacements.Keys) {
    $scriptContent = $scriptContent -replace $pattern, $replacements[$pattern]
}

# Execute the script
Invoke-Expression $scriptContent

#endregion FIRING UP MODULE STARTER

#region HANDLE PSF MODERN LOGGING
#################################################################################################
#                                                                                               #
#                            HANDLE PSF MODERN LOGGING                                          #
#                                                                                               #
#################################################################################################
Set-PSFConfig -Fullname 'PSFramework.Logging.FileSystem.ModernLog' -Value $true -PassThru | Register-PSFConfig -Scope SystemDefault

# Define the base logs path and job name
$JobName = "AAD_Migration"
$parentScriptName = Get-ParentScriptName
Write-EnhancedLog -Message "Parent Script Name: $parentScriptName"

# Call the Get-PSFCSVLogFilePath function to generate the dynamic log file path
$GetPSFCSVLogFilePathParam = @{
    LogsPath         = 'C:\Logs\PSF'
    JobName          = $jobName
    parentScriptName = $parentScriptName
}

$csvLogFilePath = Get-PSFCSVLogFilePath @GetPSFCSVLogFilePathParam
Write-EnhancedLog -Message "Generated Log File Path: $csvLogFilePath"
#endregion HANDLE PSF MODERN LOGGING


function Validate-LogRemoval {
    <#
    .SYNOPSIS
    Validates the existence of logs and associated resources before and after cleanup.

    .DESCRIPTION
    The Validate-LogRemoval function checks if the log files, registry keys, and event sources exist before and after the cleanup process.

    .PARAMETER LogName
    The name of the log to validate.

    .PARAMETER ValidateAfter
    Switch to indicate if this is a post-cleanup validation.

    .EXAMPLE
    Validate-LogRemoval -LogName "PSFramework"
    Validates the existence of PSFramework log and associated resources before cleanup.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogName,

        [Parameter(Mandatory = $false)]
        [switch]$ValidateAfter
    )

    Begin {
        $folderPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\$LogName"
        $logPath = "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\$LogName"
        $logFilePath = "C:\Windows\System32\winevt\Logs\$LogName.evtx"
        Write-EnhancedLog -Message "Starting validation for log: $LogName" -Level "NOTICE"
    }

    Process {
        try {
            $eventSourceExists = [System.Diagnostics.EventLog]::SourceExists($LogName)
            $logPathExists = Test-Path $logPath
            $folderPathExists = Test-Path $folderPath
            $logFileExists = Test-Path $logFilePath

            if ($ValidateAfter) {
                Write-EnhancedLog -Message "Post-cleanup validation for log: $LogName" -Level "NOTICE"
                if (-not $eventSourceExists -and -not $logPathExists -and -not $folderPathExists -and -not $logFileExists) {
                    Write-EnhancedLog -Message "Log $LogName and associated resources have been successfully removed." -Level "INFO"
                    return $true
                }
                else {
                    Write-EnhancedLog -Message "Log $LogName and/or associated resources still exist after cleanup." -Level "WARNING"
                    return $false
                }
            }
            else {
                Write-EnhancedLog -Message "Pre-cleanup validation for log: $LogName" -Level "NOTICE"
                if ($eventSourceExists -or $logPathExists -or $folderPathExists -or $logFileExists) {
                    Write-EnhancedLog -Message "Log $LogName and/or associated resources exist before cleanup." -Level "INFO"
                    return $true
                }
                else {
                    Write-EnhancedLog -Message "Log $LogName and associated resources do not exist before cleanup." -Level "WARNING"
                    return $false
                }
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred during validation for log $LogName $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Validation completed for log: $LogName" -Level "NOTICE"
    }
}

function Remove-Logs {
    <#
    .SYNOPSIS
    Removes specified logs and associated resources from the system.

    .DESCRIPTION
    The Remove-Logs function deletes event logs, registry keys, and event sources based on a list of patterns.

    .PARAMETER LogPatterns
    An array of log name patterns to search for and remove.

    .EXAMPLE
    Remove-Logs -LogPatterns @("PSFramework", "AppLog", "PSF")
    Removes logs and associated resources that match the provided patterns.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$LogPatterns
    )

    Begin {
        Write-EnhancedLog -Message "Starting Remove-Logs function" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Initialize counters for summary report
        $totalLogs = 0
        $logsRemoved = 0
        $logsFailed = 0

        # Retrieve all logs that match any of the patterns
        $logsToRemove = Get-WinEvent -ListLog * | Where-Object {
            $_.LogName -match ($LogPatterns -join "|")
        }

        # Stop the Windows Event Log service before starting the cleanup
        Write-EnhancedLog -Message "Stopping the Windows Event Log service..." -Level "INFO"
        Stop-Service -Name "EventLog" -Force
        Start-Sleep -Seconds 5
    }

    Process {
        foreach ($log in $logsToRemove) {
            $totalLogs++
            $logName = $log.LogName

            # Validate before cleanup
            $preValidation = Validate-LogRemoval -LogName $logName

            if ($preValidation) {
                $folderPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\$logName"
                $logPath = "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\$logName"
                $logFilePath = "C:\Windows\System32\winevt\Logs\$logName.evtx"

                # Check if the event source is different from the log name before deleting
                if ([System.Diagnostics.EventLog]::SourceExists($logName) -and ($logName -ne $logName)) {
                    try {
                        [System.Diagnostics.EventLog]::DeleteEventSource($logName)
                        Write-EnhancedLog -Message "Event source '$logName' deleted." -Level "INFO"
                    }
                    catch {
                        Write-EnhancedLog -Message "Failed to delete event source '$logName': $($_.Exception.Message)" -Level "WARNING"
                    }
                }
                else {
                    Write-EnhancedLog -Message "Event source '$logName' matches log name and cannot be deleted." -Level "WARNING"
                }

                # Delete the custom log registry key
                if (Test-Path $logPath) {
                    Remove-Item -Path $logPath -Recurse -Force
                    Write-EnhancedLog -Message "Custom log '$logPath' deleted." -Level "INFO"
                }
                else {
                    Write-EnhancedLog -Message "Custom log '$logPath' does not exist." -Level "INFO"
                }

                # Delete the custom folder (channel) registry key
                if (Test-Path $folderPath) {
                    Remove-Item -Path $folderPath -Recurse -Force
                    Write-EnhancedLog -Message "Custom folder (channel) '$folderPath' deleted." -Level "INFO"
                }
                else {
                    Write-EnhancedLog -Message "Custom folder (channel) '$folderPath' does not exist." -Level "INFO"
                }

                # Delete the actual log file
                if (Test-Path $logFilePath) {
                    Remove-Item -Path $logFilePath -Force
                    Write-EnhancedLog -Message "Log file '$logFilePath' deleted." -Level "INFO"
                }
                else {
                    Write-EnhancedLog -Message "Log file '$logFilePath' does not exist." -Level "INFO"
                }

                # Validate after cleanup
                $postValidation = Validate-LogRemoval -LogName $logName -ValidateAfter

                if ($postValidation) {
                    $logsRemoved++
                }
                else {
                    $logsFailed++
                }

                Write-EnhancedLog -Message "Cleanup for $logName completed." -Level "NOTICE"
            }
            else {
                Write-EnhancedLog -Message "Log $logName does not exist before cleanup, skipping..." -Level "WARNING"
            }
        }
    }

    End {
        # Start the Windows Event Log service again after the entire loop
        Write-EnhancedLog -Message "Starting the Windows Event Log service..." -Level "INFO"
        Start-Service -Name "EventLog"

        # Restart all key services related to event logs
        $services = @('Winmgmt', 'MSDTC')
        foreach ($service in $services) {
            Restart-Service -Name $service -Force
            Write-EnhancedLog -Message "$service restarted." -Level "INFO"
        }

        # Summary report
        Write-EnhancedLog -Message "Log removal process complete. The Windows Event Log service has been restarted." -Level "NOTICE"
        Write-EnhancedLog -Message "Summary Report:" -Level "NOTICE"
        Write-EnhancedLog -Message "Total Logs Processed: $totalLogs" -Level "INFO"
        Write-EnhancedLog -Message "Logs Successfully Removed: $logsRemoved" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        Write-EnhancedLog -Message "Logs Failed to Remove: $logsFailed" -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)

        # Optional reboot (commented out)
        Write-EnhancedLog -Message "Rebooting the system..." -Level "WARNING"
        Restart-Computer -Force
    }
}

# Run the Remove-Logs function with the desired log patterns
$logPatterns = @("PSFramework", "AppLog", "PSF", "System.Collections.Hashtable")
Remove-Logs -LogPatterns $logPatterns