# Load PSFramework module if not already loaded
if (-not (Get-Module -ListAvailable -Name PSFramework)) {
    Import-Module PSFramework
}

# Set a custom log file name pattern
$customLogFileName = "CustomLogFileName_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$(Get-Random).log"

# Configure PSFramework logging settings
Set-PSFConfig -FullName 'PSFramework.Logging.FileSystem.Path' -Value "$env:USERPROFILE\AppData\Roaming\CustomLogs" -PassThru | Register-PSFConfig -Scope UserDefault
Set-PSFConfig -FullName 'PSFramework.Logging.FileSystem.FileName' -Value $customLogFileName -PassThru | Register-PSFConfig -Scope UserDefault

# Example of writing a log entry
Write-PSFMessage -Level Significant -Message "This is a log entry with a custom file name."
