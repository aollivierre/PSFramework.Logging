$folderName = "MyCompany3"
$logName = "MyCustomApp3"
$primaryLocation = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels"

# Create the folder (registry key) for your custom logs
$eventRoot = Join-Path $primaryLocation $folderName

if (-not (Test-Path $eventRoot)) {
    New-Item -Path $eventRoot
    Write-Host "Created registry key for $folderName."
}

# Create the subkey for your custom log
$logKeyPath = Join-Path $eventRoot $logName
if (-not (Test-Path $logKeyPath)) {
    New-Item -Path $logKeyPath
    Set-ItemProperty -Path $logKeyPath -Name "Enabled" -Value 1
    Set-ItemProperty -Path $logKeyPath -Name "Type" -Value 1
    Set-ItemProperty -Path $logKeyPath -Name "Isolation" -Value 0
    Set-ItemProperty -Path $logKeyPath -Name "OwningPublisher" -Value "{Your-Provider-GUID}"
    Write-Host "Created custom log $logName under $folderName."
}
