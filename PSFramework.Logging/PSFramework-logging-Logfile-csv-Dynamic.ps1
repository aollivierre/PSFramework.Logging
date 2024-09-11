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
    '\$SkipPSGalleryModules = \$false'   = '$SkipPSGalleryModules = $True'
    '\$SkipCheckandElevate = \$false'    = '$SkipCheckandElevate = $True'
    '\$SkipAdminCheck = \$false'         = '$SkipAdminCheck = $True'
    '\$SkipPowerShell7Install = \$false' = '$SkipPowerShell7Install = $True'
    '\$SkipModuleDownload = \$false'     = '$SkipModuleDownload = $True'
}

# Apply the replacements
foreach ($pattern in $replacements.Keys) {
    $scriptContent = $scriptContent -replace $pattern, $replacements[$pattern]
}

# Execute the script
Invoke-Expression $scriptContent

#endregion FIRING UP MODULE STARTER

# Define the base logs path and job name
$JobName = "AAD_Migration"
$parentScriptName = Get-ParentScriptName
Write-Host "Parent Script Name: $parentScriptName"

# Call the Get-PSFCSVLogFilePath function to generate the dynamic log file path
$paramGetPSFCSVLogFilePath = @{
    LogsPath         = 'C:\temp\Logs\PSF'
    JobName          = $jobName
    parentScriptName = $parentScriptName
}

$csvLogFilePath = Get-PSFCSVLogFilePath @paramGetPSFCSVLogFilePath
Write-Host "Generated Log File Path: $csvLogFilePath"

# Configure the PSFramework logging provider to use CSV format
$instanceName = "$parentScriptName-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$paramSetPSFLoggingProvider = @{
    Name            = 'logfile'
    InstanceName    = $instanceName  # Use a unique instance name
    FilePath        = $csvLogFilePath  # Use the dynamically generated file path
    Enabled         = $true
    FileType        = 'CSV'
    EnableException = $true
}
Set-PSFLoggingProvider @paramSetPSFLoggingProvider

try {
    # Write a test log message
    Write-PSFMessage -Level Verbose -Message "Hello World"

    # Your script logic here
    Write-PSFMessage -Level Significant -Message "Script logic running..."
}
catch {
    # Log the error
    Write-PSFMessage -Level Error -Message "An error occurred: $_"

    # Ensure the log is written before proceeding
    Wait-PSFMessage

    # Stop logging in case of an error by disabling the provider
    Set-PSFLoggingProvider -Name 'logfile' -InstanceName $instanceName -Enabled $false

    # Re-throw the error if needed
    throw $_
}
finally {


    Write-PSFMessage -Level Significant -Message "Logging has been stopped."

    # Ensure the log is written before proceeding
    Wait-PSFMessage

    # Stop logging in the finally block by disabling the provider
    Set-PSFLoggingProvider -Name 'logfile' -InstanceName $instanceName -Enabled $false
}
