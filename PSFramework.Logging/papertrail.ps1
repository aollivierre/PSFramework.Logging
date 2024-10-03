# Define Papertrail log destination
$papertrailUrl = "http://logs.papertrailapp.com:51446"  # Replace with your Papertrail URL

# Define log file path
$logDirectory = "C:\logs"
$logFiles = Get-ChildItem -Path $logDirectory -Filter *.log

foreach ($logFile in $logFiles) {
    # Read log file content
    $logContent = Get-Content -Path $logFile.FullName
    
    # Send logs line by line to Papertrail
    foreach ($line in $logContent) {
        # Create a message to send
        $message = @{
            'message' = $line
        }
        
        # Send log message to Papertrail via HTTP POST
        Invoke-RestMethod -Uri $papertrailUrl -Method Post -Body ($message | ConvertTo-Json) -ContentType "application/json"
    }
}
