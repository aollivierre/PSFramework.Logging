# Install the PSFramework module if not already installed
# Install-Module -Name PSFramework -Scope CurrentUser -Force -AllowClobber

# Define the base log file path
$baseLogPath = "C:\temp\Logs"

# Create the Logs directory if it doesn't exist
if (-not (Test-Path $baseLogPath)) {
    New-Item -Path $baseLogPath -ItemType Directory
}

# Define the list of log file types and their extensions
$logFileTypes = @{
    CSV     = 'csv'
    Json    = 'json'
    XML     = 'xml'
    CMTrace = 'log'
}

foreach ($logFileType in $logFileTypes.Keys) {
    # Set the log file path based on the type
    $logFilePath = "$baseLogPath\HelloWorld-$logFileType.%Date%.$($logFileTypes[$logFileType])"

    # Set the logging provider for each type
    $paramSetPSFLoggingProvider = @{
        Name         = 'logfile'
        InstanceName = "HelloWorld$logFileType"
        FilePath     = $logFilePath
        FileType     = $logFileType
        Enabled      = $true
    }
    Set-PSFLoggingProvider @paramSetPSFLoggingProvider

    # Log the message specific to each format
    Write-PSFMessage -Level Host -Message "Hello World in $logFileType"

    # Ensure the log is written before proceeding
    Wait-PSFMessage

    # Optionally disable the logging provider or reset it after each loop
    Set-PSFLoggingProvider -Name 'logfile' -Enabled $false
}

# Example of final logging command for verification
# Write-PSFMessage -Level Notice -Message "Logging for each type completed."
