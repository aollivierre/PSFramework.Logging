#region FIRING UP MODULE STARTER
#################################################################################################
#                                                                                               #
#                                 FIRING UP MODULE STARTER                                      #
#                                                                                               #
#################################################################################################

# Fetch the script content
$scriptContent = Invoke-RestMethod "https://raw.githubusercontent.com/aollivierre/module-starter/main/Module-Starter.ps1"

# Define replacements in a hashtable
$replacements = @{
    '\$Mode = "dev"'                     = '$Mode = "dev"'
    '\$SkipPSGalleryModules = \$false'   = '$SkipPSGalleryModules = $True'
    '\$SkipCheckandElevate = \$false'    = '$SkipCheckandElevate = $True'
    '\$SkipAdminCheck = \$false'         = '$SkipAdminCheck = $True'
    '\$SkipPowerShell7Install = \$false' = '$SkipPowerShell7Install = $True'
    '\$SkipModuleDownload = \$false'     = '$SkipModuleDownload = $True'
}

# Apply the replacements
foreach ($pattern in $replacements.Keys) {
    $scriptContent = $scriptContent -replace $pattern, $replacements[$pattern]
}

# Execute the script
Invoke-Expression $scriptContent

#endregion FIRING UP MODULE STARTER

# Define the paths to search for log files
# $PS7psFrameworkLogDir = "C:\Users\Admin-Abdullah\AppData\Roaming\PowerShell\PSFramework\Logs\"
# $PS5psFrameworkLogDir = "C:\Users\Admin-Abdullah\AppData\Roaming\WindowsPowerShell\PSFramework\Logs\"
$customLogDir = "C:\Logs\PSF"

# Initialize a Generic List to store all log entries
$allLogEntries = [System.Collections.Generic.List[PSCustomObject]]::new()

# Initialize counters for log levels and error tracking
$logLevelCounts = @{
    "ERROR"           = 0
    "WARNING"         = 0
    "INFO"            = 0
    "DEBUG"           = 0
    "CRITICAL"        = 0
    "IMPORTANT"       = 0
    "SIGNIFICANT"     = 0
    "VERBOSE"         = 0
    "VERYVERBOSE"     = 0
    "SOMEWHATVERBOSE" = 0
    "SYSTEM"          = 0
}

$commonErrors = @{}

# Collect all log files from both directories
# $logFiles = Get-ChildItem -Path $psFrameworkLogDir, $customLogDir -Filter "*.log" -Recurse

# Collect all log files from both directories
try {
    # Write-EnhancedLog -Message "Starting to collect log files from directories: $PS7psFrameworkLogDir, $PS5psFrameworkLogDir and $customLogDir" -Level "NOTICE"
    Write-EnhancedLog -Message "Starting to collect log files from directory: $customLogDir" -Level "NOTICE"
    
    # Gather the log files
    # $logFiles = Get-ChildItem -Path $PS7psFrameworkLogDir, $PS5psFrameworkLogDir, $customLogDir -Filter "*.log" -Recurse

    # Gather the log files
    $GetChildItemParams = @{
        Path    = @(
            # $PS7psFrameworkLogDir,
            # $PS5psFrameworkLogDir,
            $customLogDir
        )
        Filter  = "*.log"
        Recurse = $true
    }
    
    $logFiles = Get-ChildItem @GetChildItemParams

    $DBG
    
    
    # Log the number of files found
    $logFileCount = $logFiles.Count
    Write-EnhancedLog -Message "Total log files found: $logFileCount" -Level "INFO"

    # List all the log files found
    foreach ($logFile in $logFiles) {
        Write-EnhancedLog -Message "Found log file: $($logFile.FullName)" -Level "INFO"
    }

    # Handle if no log files were found
    if ($logFileCount -eq 0) {
        Write-EnhancedLog -Message "No log files found in the specified directories." -Level "WARNING"
    }
} 
catch {
    Write-EnhancedLog -Message "An error occurred while collecting log files: $_" -Level "ERROR"
    Handle-Error -ErrorRecord $_
    throw $_
}

$DBG


# Loop through each log file and import its content
foreach ($logFile in $logFiles) {
    $logEntries = Import-Csv -Path $logFile.FullName
    foreach ($entry in $logEntries) {
        # Ensure the entry has a Timestamp property and parse it
        if ($entry.PSObject.Properties["Timestamp"]) {
            $parsedTimestamp = [DateTime]::ParseExact($entry.Timestamp, 'M/d/yyyy h:mm:ss tt', $null)

            # Modify the Message field to exclude the log level
            $cleanedMessage = $entry.Message -replace '^\[.*?\]\s*', ''

            # Add the file name and cleaned message as new columns, exclude SortingID for now
            $newEntry = [PSCustomObject]@{
                FileName     = $logFile.Name
                SortingID    = 0  # Placeholder, will be updated later
                Timestamp    = $parsedTimestamp
                ComputerName = $entry.ComputerName
                Username     = $entry.Username
                Level        = $entry.Level
                FunctionName = $entry.FunctionName
                Message      = $cleanedMessage
                Type         = $entry.Type
                ModuleName   = $entry.ModuleName
                File         = $entry.File
                Line         = $entry.Line
                Tags         = $entry.Tags
                TargetObject = $entry.TargetObject
                Runspace     = $entry.Runspace
                Callstack    = $entry.Callstack
            }

            # Add the new entry to the list
            $allLogEntries.Add($newEntry)

            # Update the log level counts
            $level = $entry.Level.ToUpper()
            if ($logLevelCounts.ContainsKey($level)) {
                $logLevelCounts[$level]++
            }

            # Track common errors
            if ($level -eq "ERROR" -or $level -eq "CRITICAL") {
                if ($commonErrors.ContainsKey($cleanedMessage)) {
                    $commonErrors[$cleanedMessage]++
                }
                else {
                    $commonErrors[$cleanedMessage] = 1
                }
            }
        }
    }
}

# Sort all entries by the Timestamp to maintain chronological order
$sortedLogEntries = $allLogEntries | Sort-Object -Property Timestamp

# Assign SortingID starting from 1000
$sortingCounter = 1000
foreach ($entry in $sortedLogEntries) {
    $entry.SortingID = $sortingCounter
    $sortingCounter++
}

# Insert line separators between log files after sorting
$finalLogEntries = [System.Collections.Generic.List[PSCustomObject]]::new()
$previousFileName = ""

foreach ($entry in $sortedLogEntries) {
    if ($previousFileName -ne $entry.FileName) {
        if ($previousFileName -ne "") {
            # Skip the first separator
            # Add an empty entry to create a visual separation between files
            $finalLogEntries.Add([PSCustomObject]@{ 
                    FileName     = ''
                    SortingID    = ''
                    Timestamp    = ''
                    ComputerName = ''
                    Username     = ''
                    Level        = ''
                    Message      = ''
                    Type         = ''
                    FunctionName = ''
                    ModuleName   = ''
                    File         = ''
                    Line         = ''
                    Tags         = ''
                    TargetObject = ''
                    Runspace     = ''
                    Callstack    = ''
                })
        }
        $previousFileName = $entry.FileName
    }
    $finalLogEntries.Add($entry)
}

# Generate Log Summary Report
Write-Host "`nLog Summary Report:" -ForegroundColor Cyan
Write-Host "=====================`n"

# Output the number of entries per log level
foreach ($level in $logLevelCounts.Keys) {
    $count = $logLevelCounts[$level]
    $color = switch ($level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "CRITICAL" { "Magenta" }
        "INFO" { "Green" }
        "DEBUG" { "Gray" }
        "IMPORTANT" { "Cyan" }
        default { "White" }
    }
    Write-Host "$level $count" -ForegroundColor $color
}

# Output the most common errors (optional)
if ($commonErrors.Count -gt 0) {
    Write-Host "`nMost Common Errors:" -ForegroundColor Red
    Write-Host "====================="
    foreach ($errorMessage in $commonErrors.Keys | Sort-Object -Descending) {
        Write-Host "$errorMessage $($commonErrors[$errorMessage]) occurrences" -ForegroundColor Red
    }
}

Write-Host "`nReport generated successfully!" -ForegroundColor Green

# Get the computer name to append to the title
$computerName = $env:COMPUTERNAME

# Display all log entries in an interactive grid view
if ($finalLogEntries.Count -gt 0) {
    $finalLogEntries | Out-GridView -Title "PSF Log Viewer - $computerName"
}
else {
    Write-Host "No log entries found in the specified directories." -ForegroundColor Yellow
}
