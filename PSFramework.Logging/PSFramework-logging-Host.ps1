# Import-Module C:\code\Modulesv2-BETA\EnhancedLoggingAO\EnhancedLoggingAO.psm1
# Import-Module C:\code\Modulesv2\EnhancedLoggingAO\EnhancedLoggingAO.psm1
# Install-Module PSFramework

Import-Module PSFramework

# Write-PSFMessage "<Whatever>"

Write-PSFMessage -Level Host -Message "Hello World"

Write-PSFMessage -Level Host -Message "Operation completed successfully."

Write-PSFMessage -Level Debug -Message "Variable X has been set to 123."

Write-PSFMessage -Level Verbose -Message "Starting the data import process."


Write-PSFMessage -Level Error -Message "Hello World this is ERROR"


# Write-EnhancedLog -Message "Hello World" -Level "Notice"