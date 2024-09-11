# Define the log name and file path
$logName = "MyCompany"

# Delete the log using wevtutil
wevtutil el | Where-Object {$_ -eq $logName} | ForEach-Object { wevtutil cl $_ }
wevtutil sl $logName /e:false

# Remove the associated log file manually if necessary
$logFilePath = "C:\Windows\System32\winevt\Logs\$logName.evtx"
if (Test-Path $logFilePath) {
    Remove-Item -Path $logFilePath -Force
    Write-Host "Log file '$logFilePath' deleted."
} else {
    Write-Host "Log file '$logFilePath' does not exist."
}

# Optionally, clean up registry if needed
$logRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\$logName"
if (Test-Path $logRegistryPath) {
    Remove-Item -Path $logRegistryPath -Recurse -Force
    Write-Host "Registry key '$logRegistryPath' deleted."
} else {
    Write-Host "Registry key '$logRegistryPath' does not exist."
}
