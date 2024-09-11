# Ensure PSFramework is installed and loaded
if (-not (Get-Module -ListAvailable -Name PSFramework)) {
    Install-Module -Name PSFramework -Scope CurrentUser -Force
}

Import-Module PSFramework

# Configure the PSFramework logging provider to use CSV format
$paramSetPSFLoggingProvider = @{
    Name         = 'logfile'
    InstanceName = 'MyLogInstance'
    FilePath     = 'C:\temp\Logs\MyLogFile-%Date%.csv'
    Enabled      = $true
    FileType     = 'CSV'
}
Set-PSFLoggingProvider @paramSetPSFLoggingProvider

# Write a test log message
Write-PSFMessage -Level Verbose -Message "Hello World"
