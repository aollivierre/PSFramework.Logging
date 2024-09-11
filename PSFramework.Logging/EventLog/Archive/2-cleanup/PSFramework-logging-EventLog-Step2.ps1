# Step 1: Create a custom event log and source
$logName = "PSFCustomLog"
$sourceName = "MyScriptSource"

# Check if the event log already exists
if (-not (Get-EventLog -LogName $logName -ErrorAction SilentlyContinue)) {
    # Create the custom event log
    New-EventLog -LogName $logName -Source $sourceName
    Write-Host "Event log '$logName' with source '$sourceName' created successfully."
} else {
    Write-Host "Event log '$logName' already exists."
}

# Step 2: Write an event to the custom event log
$eventMessage = "This is a test event log entry."
Write-EventLog -LogName $logName -Source $sourceName -EventID 1000 -EntryType Information -Message $eventMessage

Write-Host "Event log entry written successfully."

# Step 3: Read the latest event from the custom event log
$latestEvent = Get-EventLog -LogName $logName -Newest 1
Write-Host "Latest event log entry:"
Write-Host $latestEvent.Message
