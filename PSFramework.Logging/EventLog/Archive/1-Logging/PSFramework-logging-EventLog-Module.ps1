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

$instanceName = "$parentScriptName-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Configure the PSFramework logging provider to use CSV format
# $paramSetPSFLoggingProvider = @{
#     Name            = 'logfile'
#     InstanceName    = $instanceName  # Use a unique instance name
#     FilePath        = $csvLogFilePath  # Use the dynamically generated file path
#     Enabled         = $true
#     FileType        = 'CSV'
#     EnableException = $true
# }
# Set-PSFLoggingProvider @paramSetPSFLoggingProvider

# Get the name of the calling function
# $callingFunction = (Get-PSCallStack)[1].FunctionName

# Set up the EventLog logging provider with the calling function as the source
# $paramSetPSFLoggingProvider = @{
#     Name         = 'EventLog'
#     InstanceName = 'DynamicEventLog'
#     # InstanceName = $instanceName
#     Enabled      = $true
#     # LogName      = $parentScriptName
#     LogName      = 'PSF'
#     Source       = $callingFunction
# }
# Set-PSFLoggingProvider @paramSetPSFLoggingProvider

# Write-EnhancedLog -Message "This is a test from $parentScriptName via PSF to Event Logs" -Level 'INFO'

# $DBG

#endregion HANDLE PSF MODERN LOGGING


function Register-EventLog {
    param (
        [string]$LogName,
        [string]$SourceName
    )

    # Check if the source already exists
    if ([System.Diagnostics.EventLog]::SourceExists($SourceName)) {
        $existingLogName = [System.Diagnostics.EventLog]::LogNameFromSourceName($SourceName, $null)
        if ($existingLogName -eq $LogName) {
            Write-Host "Source '$SourceName' already exists in log '$LogName'."
        }
        else {
            Write-Host "Source '$SourceName' exists in a different log ('$existingLogName'). Removing it."
            [System.Diagnostics.EventLog]::DeleteEventSource($SourceName)
        }
    }

    # Create the event log and source if not already present
    if (-not [System.Diagnostics.EventLog]::SourceExists($SourceName)) {
        [System.Diagnostics.EventLog]::CreateEventSource($SourceName, $LogName)
        Write-Host "Event log '$LogName' with source '$SourceName' created."
    }
}



function Log-ToEventLog {
    param (
        [string]$Message,
        [string]$Level = 'Host'
    )

    # Get the name of the calling function
    $callingFunction = (Get-PSCallStack)[1].FunctionName

    # Example usage
    Register-EventLog -LogName $parentScriptName -SourceName $callingFunction

    # Set up the EventLog logging provider with the calling function as the source
    $paramSetPSFLoggingProvider = @{
        Name         = 'EventLog'
        # InstanceName = 'DynamicEventLog'
        InstanceName = $instanceName
        Enabled      = $true
        # LogName      = 'PSF'
        LogName      = $parentScriptName
        Source       = $callingFunction
        # Source       =  "$parentScriptName-$callingFunction"
        # Source       =  "$parentScriptName"
    }
    Set-PSFLoggingProvider @paramSetPSFLoggingProvider

    # Log the message to the Event Log
    Write-PSFMessage -Level $Level -Message $Message
}

# Example of calling the function
function ExampleFunction2 {
    Log-ToEventLog -Message "Hello World from ExampleFunction2" -Level Host
}

# Call the example function
ExampleFunction2

# Check the Event Log to verify the entry
# Get-EventLog -LogName 'PSF' -Source "$parentScriptName-$callingFunction" -Newest 1
# Get-EventLog -LogName 'PSF' -Source "$parentScriptName" -Newest 1
Get-EventLog -LogName $parentScriptName -Source 'ExampleFunction2' -Newest 1