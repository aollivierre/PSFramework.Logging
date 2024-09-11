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
        [string]$SourceName
    )

    # Assuming $parentScriptName is already defined earlier in your script
    # $parentScriptName = Get-ParentScriptName

    # Generate the first 8 characters using the current time to ensure uniqueness
    $uniqueBase = (Get-Date).ToString("HHmmssff")  # HHmmssff for hours, minutes, seconds, and fractions of a second

    # Combine the unique base with the pre-generated parent script name
    $logName = $uniqueBase + "-" + $parentScriptName

    # Store the filtered logs in an array first to avoid pipeline errors
    $logs = @()
    try {
        $logs = @(Get-WinEvent -ListLog * | Where-Object { $_.LogName -like "*$parentScriptName*" })
    }
    catch {
        Write-Warning "Failed to access some logs due to insufficient privileges or another issue: $_"
    }

    # Then select the first log from the array
    $existingLog = $logs | Select-Object -First 1

    if ($existingLog) {
        # If a log with the same parent script name exists, use that log
        $logName = $existingLog.LogName
        Write-Host "Event log with the same parent script name already exists. Using existing log: '$logName'."
    }

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

    return $logName
}





function Write-LogMessage {
    [CmdletBinding()]
    param (
        [string]$Message,
        [string]$Level = 'INFO',
        [int]$EventID = 1000
    )

    # Get the PowerShell call stack to determine the actual calling function
    $callStack = Get-PSCallStack
    $callerFunction = if ($callStack.Count -ge 2) { $callStack[1].Command } else { '<Unknown>' }

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
    $global:logName = Initialize-EventLog -SourceName $callerFunction

    # Write the message to the specified event log
    Write-EventLog -LogName $logName -Source $callerFunction -EntryType $entryType -EventId $eventID -Message $Message
    Write-Host "Logged message to '$logName' from source '$callerFunction'"
}







# Example function to demonstrate logging
function ExampleFunction {
    Write-LogMessage -Message "This is a test message from ExampleFunction." -Level "INFO"
}

# Call the function to generate a log entry
ExampleFunction

# Verify the log in Event Viewer or use Get-WinEvent
# Get-WinEvent -LogName 'AppLog10' -MaxEvents 10

if ($global:logName) {
    Get-WinEvent -LogName $global:logName -MaxEvents 10
} else {
    Write-Host "Log name not found. Please initialize it first."
}


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



