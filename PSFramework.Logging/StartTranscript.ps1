# Function to generate the log file path based on the calling function name
function Get-TranscriptFilePath {
    # Get the PowerShell call stack to determine the actual calling function
    $callStack = Get-PSCallStack
    $callerFunction = if ($callStack.Count -ge 2) { $callStack[1].Command } else { 'UnknownFunction' }

    # Get the current date in the desired format
    $currentDate = Get-Date -Format "yyyy-MM-dd"

    # Create the log file path
    $logFilePath = "C:\Logs\$callerFunction-transcript-$currentDate.log"

    return $logFilePath
}

# Generate the transcript file path
$transcriptPath = Get-TranscriptFilePath

# Start the transcript
Start-Transcript -Path $transcriptPath

# Example function that logs some actions
function ExampleFunction {
    Write-Host "This is an example action being logged."
    # Add more actions here
}

# Call the example function
ExampleFunction

# Stop the transcript
Stop-Transcript
