# Define the folder name and log name
$folderName = "MyCompany"
$logName = "MyCustomApp"

# Step 1: Create a custom event log folder
$createFolderCommand = "wevtutil im C:\Path\To\Your\EventLogConfiguration.xml"
$folderCreationXml = @"
<Channel xmlns="http://schemas.microsoft.com/win/2004/08/events">
    <ChannelType>Operational</ChannelType>
    <OwningPublisher>$folderName</OwningPublisher>
    <Name>$folderName/$logName</Name>
    <Enabled>true</Enabled>
    <Isolation>Application</Isolation>
    <Access>O:BAG:SYD:(A;;0x3;;;SY)(A;;0x3;;;BA)(A;;0x3;;;S-1-5-19)</Access>
</Channel>
"@

# Write the XML content to a temporary file
$tempFilePath = "C:\Path\To\Your\EventLogConfiguration.xml"
$folderCreationXml | Out-File -FilePath $tempFilePath -Encoding UTF8

# Run the command to create the folder and event log
Invoke-Expression $createFolderCommand

# Step 2: Write an event to the new custom event log
$eventMessage = "This is a test event under MyCustomApp."
Write-EventLog -LogName "$folderName/$logName" -Source "MyScriptSource" -EventID 1000 -EntryType Information -Message $eventMessage

Write-Host "Event log entry written successfully to $folderName/$logName."

# Step 3: Read the latest event from the custom event log
$latestEvent = Get-EventLog -LogName "$folderName/$logName" -Newest 1
Write-Host "Latest event log entry:"
Write-Host $latestEvent.Message
