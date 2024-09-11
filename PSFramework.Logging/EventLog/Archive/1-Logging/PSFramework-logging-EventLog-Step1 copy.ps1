$folderName = "MyCompany2"
$logName = "MyCustomApp2"
$eventLogRegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\$folderName"

# Step 1: Create the folder (registry key) for your custom logs
if (-not (Test-Path $eventLogRegistryPath)) {
    New-Item -Path $eventLogRegistryPath
    Write-Host "Created registry key for $folderName."
}

# Step 2: Create the subkey for your custom log
$logKeyPath = "$eventLogRegistryPath\$logName"
if (-not (Test-Path $logKeyPath)) {
    New-Item -Path $logKeyPath
    Set-ItemProperty -Path $logKeyPath -Name "Sources" -Value "MyScriptSource2"
    Set-ItemProperty -Path $logKeyPath -Name "File" -Value "C:\Windows\System32\Winevt\Logs\$folderName\$logName.evtx"
    Set-ItemProperty -Path $logKeyPath -Name "MaxSize" -Value 204800
    Write-Host "Created custom log $logName under $folderName."
}

# Step 3: Write an event to the custom log
Write-EventLog -LogName "$folderName/$logName" -Source "MyScriptSource2" -EventID 1000 -EntryType Information -Message "This is a test event."
