Import-Module C:\code\Modulesv2-BETA\EnhancedLoggingAO\EnhancedLoggingAO.psm1 -Force:$true -Verbose:$false
# Import-Module C:\code\Modulesv2\EnhancedLoggingAO\EnhancedLoggingAO.psm1
# Install-Module PSFramework

# Import-Module PSFramework -Force:$true

Write-EnhancedLog -Message "This is a debug message" -Level 'DEBUG'
Write-EnhancedLog -Message "This is an informational message" -Level 'INFO'
Write-EnhancedLog -Message "This is a notice message" -Level 'NOTICE'
Write-EnhancedLog -Message "This is a warning message" -Level 'WARNING'
Write-EnhancedLog -Message "This is an error message" -Level 'ERROR'
Write-EnhancedLog -Message "This is a critical message" -Level 'CRITICAL'
Write-EnhancedLog -Message "This is a custom color info message" -Level 'INFO' -ForegroundColor 'DarkGray'


# Write-PSFMessage -Message "<em>This is important</em> but <sub>this is less so</sub>" -Level Host


# Set the color for error messages
# Set-PSFConfig -Name 'PSFramework.message.error.color' -Value 'Red'

# Set the color for emphasized text within error messages
# Set-PSFConfig -Name 'PSFramework.message.error.color.emphasis' -Value 'DarkRed'

# Ensure settings are applied
# Invoke-PSFConfig -Module PSFramework


# Write-PSFMessage -Message "This is Error" -Level Error



# Write-PSFMessage -Level Error -Message "This is Error" -Color 'Red'


# Reset the color for error messages to the default value
# Remove-PSFConfig -Name 'PSFramework.message.error.color' -Module 'PSFramework'

# Reset the color for emphasized text within error messages to the default value
# Remove-PSFConfig -Name 'PSFramework.message.error.color.emphasis' -Module 'PSFramework'

# Apply the changes
# Invoke-PSFConfig -Module PSFramework


# Apply the changes
# Invoke-PSFConfig -Module PSFramework




# Get-PSFConfig -Module PSFramework | Where-Object Name -like '*color*'