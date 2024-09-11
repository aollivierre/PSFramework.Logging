# Create the registry keys for the custom folder and log
$folderPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\MyCompany5"
$logPath = "$folderPath\MyCustomApp5"

if (-not (Test-Path $folderPath)) {
    New-Item -Path $folderPath -Force
}

if (-not (Test-Path $logPath)) {
    New-Item -Path $logPath -Force
    Set-ItemProperty -Path $logPath -Name "Enabled" -Value 1
    Set-ItemProperty -Path $logPath -Name "Type" -Value 1
    Set-ItemProperty -Path $logPath -Name "Isolation" -Value 0
    Set-ItemProperty -Path $logPath -Name "OwningPublisher" -Value "{Your-GUID-Here}"
}

# Register the event source
$sourceParams = @{
    LogName = "MyCustomApp5"
    Source  = "MyScriptSource5"
}

if (-not [System.Diagnostics.EventLog]::SourceExists($sourceParams.Source)) {
    New-EventLog @sourceParams
}

# Write an event to the log
Write-EventLog -LogName "MyCustomApp5" -Source "MyScriptSource5" -EventID 1001 -EntryType Information -Message "Test event5"

# Read the latest event
$latestEvent = Get-WinEvent -LogName "MyCustomApp5" -MaxEvents 1
Write-Host $latestEvent.Message