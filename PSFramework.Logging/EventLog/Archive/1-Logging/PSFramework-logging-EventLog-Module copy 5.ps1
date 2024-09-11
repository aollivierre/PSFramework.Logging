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
    '\$SkipPSGalleryModules = \$false'   = '$SkipPSGalleryModules = $false'
    '\$SkipCheckandElevate = \$false'    = '$SkipCheckandElevate = $false'
    '\$SkipAdminCheck = \$false'         = '$SkipAdminCheck = $false'
    '\$SkipPowerShell7Install = \$false' = '$SkipPowerShell7Install = $false'
    '\$SkipModuleDownload = \$false'     = '$SkipModuleDownload = $false'
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

# $instanceName = "$parentScriptName-$(Get-Date -Format 'yyyyMMdd-HHmmss')"


function Initialize-EventLog {
    param (
        [string]$LogName,
        [string]$SourceName
    )

    # Ensure the first eight characters of the log name are unique
    # $logName = $LogName.Substring(0, [Math]::Min(8, $LogName.Length))

    # Check if the log exists by retrieving a list of event logs
    $logExists = [System.Diagnostics.EventLog]::Exists($logName)

    # Check if the source exists
    $sourceExists = [System.Diagnostics.EventLog]::SourceExists($SourceName)

    # Handle all scenarios
    if (-not $logExists -and -not $sourceExists) {
        # Neither the log nor the source exist, create both
        New-EventLog -LogName $logName -Source $SourceName
        Write-Host "Created event log '$logName' and source '$SourceName'."
    }
    elseif (-not $logExists -and $sourceExists) {
        # Source exists but is associated with a different log, so remove the source and create the correct log and source
        Remove-EventLog -Source $SourceName
        New-EventLog -LogName $logName -Source $SourceName
        Write-Host "Event source '$SourceName' was associated with a different log. Recreated event log '$logName' with source '$SourceName'."
    }
    elseif ($logExists -and -not $sourceExists) {
        # Log exists but the source does not, so create the source
        New-EventLog -LogName $logName -Source $SourceName
        Write-Host "Added source '$SourceName' to existing event log '$logName'."
    }
    else {
        # Both log and source exist
        Write-Host "Event log '$logName' and source '$SourceName' already exist."
    }
}



function Write-LogMessage {
    [CmdletBinding()]
    param (
        [string]$Message,
        [string]$Level = 'INFO',
        [int]$EventID = 1000
    )

    # Determine the parent script name and sanitize it
    # $parentScriptName = Get-ParentScriptName
    # $parentScriptName = [System.IO.Path]::GetFileNameWithoutExtension($parentScriptName)
    # $parentScriptName = $parentScriptName -replace '[^a-zA-Z0-9]', '_'  # Replace non-alphanumeric characters with underscores
    # $parentScriptName = $parentScriptName.Substring(0, [Math]::Min($parentScriptName.Length, 50))  # Limit length to 50 characters

    # Get the parent script name
    # $parentScriptName = ($MyInvocation.PSCommandPath | Split-Path -Leaf) -replace '\..*$', ''

    # Create a unique ID based on the current date and time
    $uniqueID = (Get-Date).ToString("yyyyMMddHHmmss")

    # Combine the unique ID with the parent script name to create a final log name
    $parentScriptName = $uniqueID.Substring(0, 6) + "-" + $parentScriptName


    # Get the PowerShell call stack to determine the actual calling function
    # $callStack = Get-PSCallStack
    # $callerFunction = if ($callStack.Count -ge 2) { $callStack[1].Command } else { '<Unknown>' }

    # Map custom levels to event log entry types and event IDs
    $entryType, $mappedEventID = switch ($Level.ToUpper()) {
        'DEBUG' { 'Information', 1001 }
        'INFO' { 'Information', 1002 }
        'NOTICE' { 'Information', 1003 }
        'WARNING' { 'Warning', 2001 }
        'ERROR' { 'Error', 3001 }
        'CRITICAL' { 'Error', 3002 }
        'IMPORTANT' { 'Information', 1004 }
        'OUTPUT' { 'Information', 1005 }
        'SIGNIFICANT' { 'Information', 1006 }
        'VERYVERBOSE' { 'Information', 1007 }
        'VERBOSE' { 'Information', 1008 }
        'SOMEWHATVERBOSE' { 'Information', 1009 }
        'SYSTEM' { 'Information', 1010 }
        'INTERNALCOMMENT' { 'Information', 1011 }
        default { 'Information', 9999 }
    }

    # Use provided EventID if specified, otherwise use mapped EventID
    $eventID = if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('EventID')) { $EventID } else { $mappedEventID }

    # Ensure the event log and source are initialized

    # $parentScriptName

    Initialize-EventLog -LogName $parentScriptName -SourceName 'AppSource10'

    # Write the message to the specified event log
    Write-EventLog -LogName $parentScriptName -Source 'AppSource10' -EntryType $entryType -EventId $eventID -Message $Message
    Write-Host "Logged message to $parentScriptName from source AppSource10."
}







# Example function to demonstrate logging
function ExampleFunction {
    Write-LogMessage -Message "This is a test message from ExampleFunction." -Level "INFO"
}

# Call the function to generate a log entry
ExampleFunction

# Verify the log in Event Viewer or use Get-WinEvent
Get-WinEvent -LogName 'AppLog10' -MaxEvents 10

# Writing to AppLog7
# Write-LogMessage -LogName "AppLog6" -SourceName "AppSource6" -Message "Message from AppSource6 in AppLog9"

# # Writing to AppLog8
# Write-LogMessage -LogName "AppLog8" -SourceName "AppSource8" -Message "Message from AppSource8 in AppLog8"


# Writing different types of messages
# Write-LogMessage -LogName "AppLog1" -SourceName "AppSource1" -Message "This is a debug message." -Level "DEBUG"
# Write-LogMessage -LogName "AppLog1" -SourceName "AppSource1" -Message "This is an informational message." -Level "INFO"
# Write-LogMessage -LogName "AppLog1" -SourceName "AppSource1" -Message "This is a warning message." -Level "WARNING"
# Write-LogMessage -LogName "AppLog1" -SourceName "AppSource1" -Message "This is an error message." -Level "ERROR"
# Write-LogMessage -LogName "AppLog1" -SourceName "AppSource1" -Message "This is a critical error message." -Level "CRITICAL"


# Check logs for AppLog7
# Get-WinEvent -LogName "AppLog6" -MaxEvents 10

# # Check logs for AppLog8
# Get-WinEvent -LogName "AppLog8" -MaxEvents 10

# Get-WinEvent -LogName "AppLog1" -MaxEvents 10



