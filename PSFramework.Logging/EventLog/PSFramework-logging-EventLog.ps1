# Install the PSFramework module if not already installed
# Install-Module -Name PSFramework -Scope CurrentUser -Force -AllowClobber

function Log-ToEventLog {
    param (
        [string]$Message,
        [string]$Level = 'Host'
    )

    # Get the name of the calling function
    $callingFunction = (Get-PSCallStack)[1].FunctionName

    # Set up the EventLog logging provider with the calling function as the source
    $paramSetPSFLoggingProvider = @{
        Name         = 'EventLog'
        InstanceName = 'DynamicEventLog'
        Enabled      = $true
        LogName      = 'PSF'
        Source       = $callingFunction
    }
    Set-PSFLoggingProvider @paramSetPSFLoggingProvider

    # Log the message to the Event Log
    Write-PSFMessage -Level $Level -Message $Message
}

# Example of calling the function
function ExampleFunction {
    Log-ToEventLog -Message "Hello World from ExampleFunction" -Level Host
}

# Call the example function
ExampleFunction

# Check the Event Log to verify the entry
Get-EventLog -LogName 'PSF' -Source 'ExampleFunction' -Newest 1