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
    if (-not (Get-EventLog -LogName $LogName -ErrorAction SilentlyContinue)) {
        if (-not [System.Diagnostics.EventLog]::SourceExists($SourceName)) {
            New-EventLog -LogName $LogName -Source $SourceName
            Write-Host "Created event log '$LogName' and source '$SourceName'."
        } else {
            Write-Host "Source '$SourceName' already exists, associated with log '$LogName'."
        }
    } else {
        Write-Host "Event log '$LogName' already exists."
    }
}



function Write-LogMessage {
    param (
        [string]$LogName,
        [string]$SourceName,
        [string]$Message,
        [string]$EntryType = 'Information',
        [int]$EventID = 1000
    )

    # Write the message to the specified event log
    Write-EventLog -LogName $LogName -Source $SourceName -EntryType $EntryType -EventId $EventID -Message $Message
    Write-Host "Logged message to '$LogName' from source '$SourceName'."
}



Initialize-EventLog -LogName "AppLog7" -SourceName "AppSource7"
Initialize-EventLog -LogName "AppLog8" -SourceName "AppSource8"


Write-LogMessage -LogName "AppLog7" -SourceName "AppSource7" -Message "Message from AppSource7 in AppLog7"
Write-LogMessage -LogName "AppLog8" -SourceName "AppSource8" -Message "Message from AppSource8 in AppLog8"


# Check logs for AppLog7
Get-WinEvent -LogName "AppLog7" -MaxEvents 10

# Check logs for AppLog8
Get-WinEvent -LogName "AppLog8" -MaxEvents 10
