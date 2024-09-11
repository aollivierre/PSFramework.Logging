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

# $instanceName = "$parentScriptName-$(Get-Date -Format 'yyyyMMdd-HHmmss')"


function Initialize-EventLog {
    param (
        [string]$LogName,
        [string]$SourceName
    )

    # Check if the log already exists; if not, create it
    if (-not [System.Diagnostics.EventLog]::SourceExists($SourceName)) {
        New-EventLog -LogName $LogName -Source $SourceName
        Write-Host "Created event log '$LogName' and source '$SourceName'."
    }
    else {
        Write-Host "Event log '$LogName' and source '$SourceName' already exist."
    }
}

function Write-LogMessage {
    [CmdletBinding()]
    param (
        [string]$LogName,
        [string]$SourceName,
        [string]$Message,
        [string]$Level = 'INFO',
        [int]$EventID = 1000
    )

    # Map custom levels to event log entry types and event IDs
    $entryType, $mappedEventID = switch ($Level.ToUpper()) {
        'DEBUG'           { 'Information', 1001 }
        'INFO'            { 'Information', 1002 }
        'NOTICE'          { 'Information', 1003 }
        'WARNING'         { 'Warning',     2001 }
        'ERROR'           { 'Error',       3001 }
        'CRITICAL'        { 'Error',       3002 }
        'IMPORTANT'       { 'Information', 1004 }
        'OUTPUT'          { 'Information', 1005 }
        'SIGNIFICANT'     { 'Information', 1006 }
        'VERYVERBOSE'     { 'Information', 1007 }
        'VERBOSE'         { 'Information', 1008 }
        'SOMEWHATVERBOSE' { 'Information', 1009 }
        'SYSTEM'          { 'Information', 1010 }
        'INTERNALCOMMENT' { 'Information', 1011 }
        default           { 'Information', 9999 }
    }

    # Use provided EventID if specified, otherwise use mapped EventID
    $eventID = if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('EventID')) { $EventID } else { $mappedEventID }

    # Ensure the event log and source are initialized
    Initialize-EventLog -LogName $LogName -SourceName $SourceName

    # Write the message to the specified event log
    Write-EventLog -LogName $LogName -Source $SourceName -EntryType $entryType -EventId $eventID -Message $Message
    Write-Host "Logged message to '$LogName' from source '$SourceName'."
}


# Writing to AppLog7
Write-LogMessage -LogName "PSFramework-logging-EventLog-Module copy 5" -SourceName "AppSource2" -Message "Message from AppSource2 in PSFramework-logging-EventLog-Module copy 5"

# Writing to AppLog8
Write-LogMessage -LogName "AppLog8" -SourceName "AppSource8" -Message "Message from AppSource8 in AppLog8"


# Writing different types of messages
Write-LogMessage -LogName "AppLog1" -SourceName "AppSource1" -Message "This is a debug message." -Level "DEBUG"
Write-LogMessage -LogName "AppLog1" -SourceName "AppSource1" -Message "This is an informational message." -Level "INFO"
Write-LogMessage -LogName "AppLog1" -SourceName "AppSource1" -Message "This is a warning message." -Level "WARNING"
Write-LogMessage -LogName "AppLog1" -SourceName "AppSource1" -Message "This is an error message." -Level "ERROR"
Write-LogMessage -LogName "AppLog1" -SourceName "AppSource1" -Message "This is a critical error message." -Level "CRITICAL"


# Check logs for AppLog7
Get-WinEvent -LogName "PSFramework-logging-EventLog-Module copy 5" -MaxEvents 10

# Check logs for AppLog8
Get-WinEvent -LogName "AppLog8" -MaxEvents 10

Get-WinEvent -LogName "AppLog1" -MaxEvents 10