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


# Define directories
$transcriptLogDir = "C:\Logs\Transcript"
$combinedLogDir = "C:\Logs\Transcript\Combined"
$date = (Get-Date).ToString("yyyy-MM-dd")
$combinedLogPath = Join-Path -Path $combinedLogDir -ChildPath "combined_transcripts_$date.log"

# Ensure the combined log directory exists
try {
    if (-not (Test-Path -Path $combinedLogDir)) {
        New-Item -Path $combinedLogDir -ItemType Directory | Out-Null
    }
}
catch {
    Write-EnhancedLog -Message "Failed to create or access the combined log directory: $_" -Level "ERROR"
    exit
}

# Initialize a list to store all log content
$logContents = [System.Collections.Generic.List[string]]::new()

# Collect all transcript log files and sort them by creation time
try {
    $transcriptFiles = Get-ChildItem -Path $transcriptLogDir -Filter "*.log" -Recurse | Sort-Object -Property CreationTime
}
catch {
    Write-EnhancedLog -Message "An error occurred while retrieving transcript files: $_" -Level "ERROR"
    exit
}

if ($transcriptFiles.Count -eq 0) {
    Write-EnhancedLog -Message "No transcript log files found in $transcriptLogDir." -Level "WARNING"
    exit
}

Write-EnhancedLog -Message "Found $($transcriptFiles.Count) transcript log files to process." -Level "INFO"

# Function to remove unwanted sections from the log content
function Remove-UnwantedSections {
    param (
        [string]$content
    )

    try {
        # Split the content by lines
        $lines = $content -split "`r`n|`n|`r"

        # Initialize a flag to track when inside the unwanted section
        $insideUnwantedSection = $false

        # Initialize a list to store the cleaned lines
        $cleanedLines = [System.Collections.Generic.List[string]]::new()

        foreach ($line in $lines) {
            if ($line -match '^\*{22}$') {
                # Toggle the flag when encountering a line with 22 asterisks
                $insideUnwantedSection = -not $insideUnwantedSection
            }
            elseif (-not $insideUnwantedSection) {
                # Add the line to cleanedLines if not inside the unwanted section
                $cleanedLines.Add($line)
            }
        }

        # Join the cleaned lines back into a single string
        return $cleanedLines -join "`n"
    }
    catch {
        Write-EnhancedLog -Message "An error occurred while cleaning the log content: $_" -Level "ERROR"
        throw $_  # Re-throw the error to be handled by the caller
    }
}

# Loop through each transcript log file and combine the content
foreach ($transcriptFile in $transcriptFiles) {
    try {
        Write-EnhancedLog -Message "Processing file: $($transcriptFile.FullName)" -Level "INFO"
        $fileContent = Get-Content -Path $transcriptFile.FullName -Raw
        
        # Remove the unwanted sections
        $cleanedContent = Remove-UnwantedSections -content $fileContent
        
        # $logContents.Add("`n`n# --- Start of $($transcriptFile.FullName) ---`n")
        $logContents.Add($cleanedContent)
        # $logContents.Add("`n# --- End of $($transcriptFile.FullName) ---`n")
    }
    catch {
        Write-EnhancedLog -Message "Failed to process $($transcriptFile.FullName): $_" -Level "ERROR"
        # Optionally continue to the next file or handle as needed
    }
}

# Join all log content into a single string
try {
    $combinedLogContent = $logContents -join "`n"

    # Save the combined content to the combined log file
    Set-Content -Path $combinedLogPath -Value $combinedLogContent
    Write-EnhancedLog -Message "Combined transcripts saved to: $combinedLogPath" -Level "INFO"
}
catch {
    Write-EnhancedLog -Message "Failed to save the combined transcript log: $_" -Level "ERROR"
    exit
}

# Open the combined log in VS Code
try {
    if (Test-Path -Path $combinedLogPath) {
        Write-EnhancedLog -Message "Opening combined transcript log in VS Code..." -Level "INFO"
        code $combinedLogPath
    }
    else {
        Write-EnhancedLog -Message "Failed to find the combined transcript log after saving." -Level "ERROR"
    }
}
catch {
    Write-EnhancedLog -Message "An error occurred while trying to open the combined log in VS Code: $_" -Level "ERROR"
}
