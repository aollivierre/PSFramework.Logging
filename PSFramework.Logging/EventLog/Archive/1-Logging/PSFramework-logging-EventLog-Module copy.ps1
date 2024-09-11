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

function Set-EventLogProvider {
    param (
        [string]$LogName,
        [string]$SourceName,
        [string]$InstanceName
    )

    $instanceName = "$parentScriptName-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

    # Set up the EventLog logging provider with the specified log name and source
    $paramSetPSFLoggingProvider = @{
        Name         = 'eventlog'
        InstanceName = $InstanceName
        LogName      = $LogName
        Source       = $SourceName
        Enabled      = $true
    }
    Set-PSFLoggingProvider @paramSetPSFLoggingProvider
}



function Log-Message {
    param (
        [string]$LogName,
        [string]$SourceName,
        [string]$Message,
        [string]$Level = 'host',
        [string]$InstanceName
    )

    # Set up the logging provider
    Set-EventLogProvider -LogName $LogName -SourceName $SourceName -InstanceName $InstanceName

    # Write the message to the event log
    Write-PSFMessage -Level $Level -Message $Message

}



# Log a message to the first event log
Log-Message -LogName "AppLog1" -SourceName "AppSource1" -Message "Message from AppSource1 in AppLog1"

# Log a message to the second event log
Log-Message -LogName "AppLog2" -SourceName "AppSource2" -Message "Message from AppSource2 in AppLog2"


# Get-EventLog -LogName "AppLog1" -Source "AppSource1" -Newest 1
# Get-EventLog -LogName "AppLog2" -Source "AppSource2" -Newest 1

Get-WinEvent -LogName "AppLog1" -MaxEvents 10
Get-WinEvent -LogName "AppLog2" -MaxEvents 10


