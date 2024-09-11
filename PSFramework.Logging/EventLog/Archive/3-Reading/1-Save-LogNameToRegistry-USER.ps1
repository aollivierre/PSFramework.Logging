function Save-LogNameToRegistry {
    <#
    .SYNOPSIS
    Saves the event log name to a registry key accessible by both USER and SYSTEM contexts.

    .DESCRIPTION
    The Save-LogNameToRegistry function stores the dynamically generated event log name in a registry key, making it accessible for scripts running in both USER and SYSTEM contexts.

    .PARAMETER LogName
    The name of the event log to be saved.

    .EXAMPLE
    Save-LogNameToRegistry -LogName "13075842-PSFrameworkloggingEventLogModulecopy18"
    Saves the log name to the registry.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogName
    )

    Begin {
        Write-EnhancedLog -Message "Starting Save-LogNameToRegistry function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            $regPath = "HKLM:\SOFTWARE\MyApp\Logging"

            if (-not (Test-Path $regPath)) {
                New-Item -Path $regPath -Force | Out-Null
                Write-EnhancedLog -Message "Created registry path: $regPath" -Level "INFO"
            }

            Set-ItemProperty -Path $regPath -Name "LogName" -Value $LogName -Force
            Write-EnhancedLog -Message "Saved log name '$LogName' to registry at '$regPath'." -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Save-LogNameToRegistry function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Save-LogNameToRegistry function" -Level "Notice"
    }
}
