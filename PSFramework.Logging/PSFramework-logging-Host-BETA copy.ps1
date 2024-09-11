Import-Module C:\code\Modulesv2-BETA\EnhancedLoggingAO\EnhancedLoggingAO.psm1 -Force:$true -Verbose:$false

# Test script for all PSFramework log levels using Write-EnhancedLog


# Write-PSFMessage -Level 'Host' -Message "This is a <em>highlighted</em> message with <err>an error part</err>."

# Write-PSFHostColor -String 'This is <c="red">red text</c> and this is <c="green">green text</c>.'

Set-PSFConfig -Fullname 'PSFramework.Logging.FileSystem.ModernLog' -Value $true


function Test-MyFunction {
    Write-EnhancedLog -Message "This is a test message from Test-MyFunction" -Level 'INFO'
}

Test-MyFunction


# # Critical level example
# Write-EnhancedLog -Message "This is a critical message" -Level 'CRITICAL'

# # Important level example
# Write-EnhancedLog -Message "This is an important message" -Level 'IMPORTANT'

# # Output level example
# Write-EnhancedLog -Message "This is an output message" -Level 'OUTPUT'

# # Host level example
# Write-EnhancedLog -Message "This is a host message" -Level 'HOST'

# # Significant level example
# Write-EnhancedLog -Message "This is a significant message" -Level 'SIGNIFICANT'

# # VeryVerbose level example
# Write-EnhancedLog -Message "This is a very verbose message" -Level 'VERYVERBOSE'

# # Verbose level example
# Write-EnhancedLog -Message "This is a verbose message" -Level 'VERBOSE'

# # SomewhatVerbose level example
# Write-EnhancedLog -Message "This is a somewhat verbose message" -Level 'SOMEWHATVERBOSE'

# # System level example
# Write-EnhancedLog -Message "This is a system message" -Level 'SYSTEM'

# # Debug level example
# Write-EnhancedLog -Message "This is a debug message" -Level 'DEBUG'

# # InternalComment level example
# Write-EnhancedLog -Message "This is an internal comment message" -Level 'INTERNALCOMMENT'

# # Warning level example
# Write-EnhancedLog -Message "This is a warning message" -Level 'WARNING'

# # Error level example
# Write-EnhancedLog -Message "This is an error message" -Level 'ERROR'

# # Info level example (mapped to Host in this setup)
# Write-EnhancedLog -Message "This is an informational message" -Level 'INFO'

# # Notice level example (mapped to Important in this setup)
# Write-EnhancedLog -Message "This is a notice message" -Level 'NOTICE'