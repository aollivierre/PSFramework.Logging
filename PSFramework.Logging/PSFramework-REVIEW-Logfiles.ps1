# $logFilePath = "C:\Users\Admin-Abdullah\AppData\Roaming\PowerShell\PSFramework\Logs\DESKTOP-9KHVRUI_13164_message_0.log"
$logFilePath = "C:\Logs\DESKTOP-9KHVRUI_10784_message_0.log"

if (-not (Test-Path -Path $logFilePath)) {
    Write-Host "Log file not found: $logFilePath" -ForegroundColor Red
    exit
}

# Import the log file as a CSV
$logEntries = Import-Csv -Path $logFilePath

# Process each log entry and display the desired fields
$logEntries | ForEach-Object {
    $timestamp = $_.Timestamp
    $level = $_.Level
    $functionName = $_.FunctionName
    $message = $_.Message

    # Remove the level from the message if it's present
    $cleanedMessage = $message -replace '^\[.*?\]\s*', ''

    # Add brackets around the level and function name
    $levelFormatted = "[$level]"
    $functionNameFormatted = "[$functionName]"

    # Determine color based on log level
    $foregroundColor = switch ($level.ToUpper()) {
        "ERROR"           { [ConsoleColor]::Red }
        "CRITICAL"        { [ConsoleColor]::Magenta }
        "WARNING"         { [ConsoleColor]::Yellow }
        "INFO"            { [ConsoleColor]::Green }
        "DEBUG"           { [ConsoleColor]::Gray }
        "SYSTEM"          { [ConsoleColor]::Cyan }
        "IMPORTANT"       { [ConsoleColor]::Blue }
        "SIGNIFICANT"     { [ConsoleColor]::DarkCyan }
        "VERYVERBOSE"     { [ConsoleColor]::DarkGray }
        "VERBOSE"         { [ConsoleColor]::DarkGreen }
        "SOMEWHATVERBOSE" { [ConsoleColor]::DarkYellow }
        default           { [ConsoleColor]::White }
    }

    # Ensure that we have a function name
    if (-not [string]::IsNullOrWhiteSpace($functionName)) {
        Write-Host "$timestamp - $levelFormatted - $functionNameFormatted - $cleanedMessage" -ForegroundColor $foregroundColor
    } else {
        Write-Host "$timestamp - $levelFormatted - [UnknownFunction] - $cleanedMessage" -ForegroundColor $foregroundColor
    }
}
