function New-CustomEventLog {
    param (
        [string]$FolderName,
        [string]$LogName,
        [string]$OwningPublisherGUID,
        [string]$PrimaryLocation = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels"
    )

    # Construct the path for the custom log
    $logKeyPath = Join-Path (Join-Path $PrimaryLocation $FolderName) $LogName

    # Create the log key if it doesn't exist
    if (-not (Test-Path $logKeyPath)) {
        New-Item -Path $logKeyPath -Force
        Set-ItemProperty -Path $logKeyPath -Name "Enabled" -Value 1
        Set-ItemProperty -Path $logKeyPath -Name "Type" -Value 1
        Set-ItemProperty -Path $logKeyPath -Name "Isolation" -Value 0
        Set-ItemProperty -Path $logKeyPath -Name "OwningPublisher" -Value $OwningPublisherGUID
        Write-Host "Created custom log $LogName under $FolderName."
    } else {
        Write-Host "Log $LogName already exists under $FolderName."
    }
}

# Parameters for creating the custom log under the folder
$logParams = @{
    FolderName          = "MyCompany4"
    LogName             = "MyCompany4/MyCustomApp4"  # Use the full path
    OwningPublisherGUID = "{Your-GUID-Here}"         # Replace with your actual GUID
}

# Create the custom log under the folder
New-CustomEventLog @logParams

# Register the event source with the full path
$sourceParams = @{
    LogName = "MyCompany4/MyCustomApp4"
    Source  = "MyScriptSource4"
}

if (-not [System.Diagnostics.EventLog]::SourceExists($sourceParams.Source)) {
    New-EventLog @sourceParams
    Write-Host "Event source '$($sourceParams.Source)' registered."
} else {
    Write-Host "Event source '$($sourceParams.Source)' already exists."
}

# Writing an Event to the Custom Log
$logName = "MyCompany4/MyCustomApp4"
$source = "MyScriptSource4"
$eventId = 1001
$entryType = "Information"
$message = "This is a test event in MyCustomApp log."

# Writing the event to the custom log
Write-EventLog -LogName $logName -Source $source -EventID $eventId -EntryType $entryType -Message $message

# Reading the Event from the Custom Log
$latestEvent = Get-WinEvent -LogName $logName -MaxEvents 1
Write-Host "Latest event in $logName log:"
Write-Host $latestEvent.Message
