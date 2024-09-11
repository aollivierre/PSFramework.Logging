$logName = "PSFramework-logging-EventLog-Module2"
$sourceName = "PSFSource"

# Check if the event log already exists
if (-not (Get-WinEvent -ListLog $logName -ErrorAction SilentlyContinue)) {
    # Create the event log and source
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        New-EventLog -LogName $logName -Source $sourceName
    } else {
        [System.Diagnostics.EventLog]::CreateEventSource($sourceName, $logName)
    }
    Write-Host "Event log '$logName' with source '$sourceName' created."
} else {
    Write-Host "Event log '$logName' already exists."
}
