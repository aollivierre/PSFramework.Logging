# Install the PSFramework module if not already installed
# Install-Module -Name PSFramework -Scope CurrentUser -Force -AllowClobber

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
    '\$SkipPSGalleryModules = \$false'   = '$SkipPSGalleryModules = $true'
    '\$SkipCheckandElevate = \$false'    = '$SkipCheckandElevate = $true'
    '\$SkipAdminCheck = \$false'         = '$SkipAdminCheck = $true'
    '\$SkipPowerShell7Install = \$false' = '$SkipPowerShell7Install = $true'
    '\$SkipModuleDownload = \$false'     = '$SkipModuleDownload = $true'
    '\$SkipGitRepos = \$false'           = '$SkipGitRepos = $true'
}

# Apply the replacements
foreach ($pattern in $replacements.Keys) {
    $scriptContent = $scriptContent -replace $pattern, $replacements[$pattern]
}

# Execute the script
Invoke-Expression $scriptContent

#endregion FIRING UP MODULE STARTER

#region HANDLE PSF MODERN LOGGING
#################################################################################################
#                                                                                               #
#                            HANDLE PSF MODERN LOGGING                                          #
#                                                                                               #
#################################################################################################
Set-PSFConfig -Fullname 'PSFramework.Logging.FileSystem.ModernLog' -Value $true -PassThru | Register-PSFConfig -Scope SystemDefault

# Define the base logs path and job name
$JobName = "AAD_Migration"
$parentScriptName = Get-ParentScriptName
Write-EnhancedLog -Message "Parent Script Name: $parentScriptName"

# Call the Get-PSFCSVLogFilePath function to generate the dynamic log file path
$GetPSFCSVLogFilePathParam = @{
    LogsPath         = 'C:\Logs\PSF'
    JobName          = $jobName
    parentScriptName = $parentScriptName
}

$csvLogFilePath = Get-PSFCSVLogFilePath @GetPSFCSVLogFilePathParam
Write-EnhancedLog -Message "Generated Log File Path: $csvLogFilePath"
#endregion HANDLE PSF MODERN LOGGING

# $instanceName = "$parentScriptName-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

function Generate-UniqueBase {
    <#
    .SYNOPSIS
    Generates a unique base identifier using the current timestamp, process ID, and a random number.

    .DESCRIPTION
    The Generate-UniqueBase function creates a unique identifier composed of parts of the current timestamp, the process ID, and a random number. This ensures uniqueness for various applications that require a simple, unique identifier.

    .PARAMETER TimestampFormat
    Specifies the format of the timestamp to use in the identifier.

    .PARAMETER ProcessIdLength
    Specifies the number of digits to use from the process ID.

    .PARAMETER RandomPartMin
    Specifies the minimum value for the random number part.

    .PARAMETER RandomPartMax
    Specifies the maximum value for the random number part.

    .EXAMPLE
    Generate-UniqueBase -TimestampFormat "yyMMddHHmm" -ProcessIdLength 4 -RandomPartMin 10 -RandomPartMax 99
    Generates a unique identifier using the specified timestamp format, process ID length, and random number range.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$TimestampFormat = "yyMMddHHmm",

        [Parameter(Mandatory = $false)]
        [int]$ProcessIdLength = 4,

        [Parameter(Mandatory = $false)]
        [int]$RandomPartMin = 10,

        [Parameter(Mandatory = $false)]
        [int]$RandomPartMax = 99
    )

    Begin {
        Write-EnhancedLog -Message "Starting Generate-UniqueBase function" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Generate the components
            $timestamp = (Get-Date).ToString($TimestampFormat)
            $processid = $PID.ToString("D$ProcessIdLength")
            $randomPart = (Get-Random -Minimum $RandomPartMin -Maximum $RandomPartMax).ToString("D2")

            Write-EnhancedLog -Message "Generated timestamp: '$timestamp', Process ID: '$processid', Random Part: '$randomPart'" -Level "INFO"

            # Adjust the components to ensure the length is 8 characters
            Write-EnhancedLog -Message "Original lengths -> Timestamp: $($timestamp.Length), Process ID: $($processid.Length), Random Part: $($randomPart.Length)" -Level "INFO"

            $uniqueBase = $timestamp.Substring($timestamp.Length - 4, 4) + $processid.Substring(0, 2) + $randomPart

            Write-EnhancedLog -Message "Generated Unique Base (before validation): '$uniqueBase', Length: $($uniqueBase.Length)" -Level "INFO"

            # Validate that the unique base is exactly 8 characters long
            if ($uniqueBase.Length -ne 8) {
                $errorMessage = "The generated unique base '$uniqueBase' is not 8 characters long. It is $($uniqueBase.Length) characters. Halting script execution."
                Write-EnhancedLog -Message $errorMessage -Level "CRITICAL" -ForegroundColor ([ConsoleColor]::Red)
                throw $errorMessage
            }

            Write-EnhancedLog -Message "Unique base successfully generated: $uniqueBase" -Level "INFO"
            return $uniqueBase
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Generate-UniqueBase function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Generate-UniqueBase function" -Level "NOTICE"
    }
}

function Validate-EventLog {
    <#
    .SYNOPSIS
    Validates whether an event log and its associated source exist and are correctly configured.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogName,

        [Parameter(Mandatory = $true)]
        [string]$SourceName,

        [Parameter(Mandatory = $false)]
        [switch]$PostValidation
    )

    Begin {
        Write-EnhancedLog -Message "Starting Validate-EventLog function" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Validate if the log exists
            Write-EnhancedLog -Message "Validating if event log '$LogName' exists." -Level "INFO"
            $logExists = @(Get-WinEvent -ListLog * | Where-Object { $_.LogName -eq $LogName }).Count -gt 0
            Write-EnhancedLog -Message "Event log '$LogName' existence: $logExists" -Level "INFO"

            # Validate if the source exists
            Write-EnhancedLog -Message "Validating if event source '$SourceName' exists." -Level "INFO"
            $sourceExists = [System.Diagnostics.EventLog]::SourceExists($SourceName)
            Write-EnhancedLog -Message "Event source '$SourceName' existence: $sourceExists" -Level "INFO"

            $sourceLogName = if ($sourceExists) { 
                [System.Diagnostics.EventLog]::LogNameFromSourceName($SourceName, ".") 
            }
            else { 
                Write-EnhancedLog -Message "Event source '$SourceName' is not associated with any log." -Level "WARNING"
                $null 
            }

            Write-EnhancedLog -Message "Event source '$SourceName' is associated with log: $sourceLogName" -Level "INFO"

            # Return the validation results as a hashtable
            $result = @{
                LogExists     = $logExists
                SourceExists  = $sourceExists
                SourceLogName = $sourceLogName
            }

            # Ensure the result is correctly returned as a hashtable
            if ($result -is [System.Collections.Hashtable]) {
                Write-EnhancedLog -Message "Returning validation result as a hashtable: LogExists = $($result['LogExists']), SourceExists = $($result['SourceExists']), SourceLogName = $($result['SourceLogName'])" -Level "INFO"
            }
            else {
                Write-EnhancedLog -Message "Unexpected data type for validation result. Expected a hashtable." -Level "ERROR"
                throw "Unexpected data type for validation result."
            }

            return $result
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Validate-EventLog function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Validate-EventLog function" -Level "NOTICE"
    }
}

function Manage-EventLogSource {
    <#
    .SYNOPSIS
    Manages the event log source, ensuring it is correctly associated with the specified event log.

    .DESCRIPTION
    The Manage-EventLogSource function checks the current state of the event log and source. It handles scenarios where the log or source might not exist, or where the source is associated with a different log, and ensures that the event log and source are properly created or reassigned.

    .PARAMETER LogName
    The name of the event log.

    .PARAMETER SourceName
    The name of the event source.

    .PARAMETER ValidationResult
    A hashtable containing the results of the pre-validation process, including whether the log and source exist and their associations.

    .EXAMPLE
    Manage-EventLogSource -LogName "MyLog" -SourceName "MySource" -ValidationResult $validationResult
    Ensures that the event log "MyLog" is correctly associated with the source "MySource."
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogName,

        [Parameter(Mandatory = $true)]
        [string]$SourceName,

        [Parameter(Mandatory = $true)]
        [hashtable]$ValidationResult
    )

    Begin {
        Write-EnhancedLog -Message "Starting Manage-EventLogSource function" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            if (-not $ValidationResult.LogExists -and -not $ValidationResult.SourceExists) {
                # Neither the log nor the source exist, create both
                Write-EnhancedLog -Message "Neither log nor source exists. Creating both." -Level "INFO"
                New-EventLog -LogName $LogName -Source $SourceName
                Write-EnhancedLog -Message "Created event log '$LogName' and source '$SourceName'." -Level "INFO"
            }
            elseif ($ValidationResult.LogExists -and $ValidationResult.SourceExists -and $ValidationResult.SourceLogName -ne $LogName) {
                # Both log and source exist but the source is associated with a different log
                Write-EnhancedLog -Message "Source exists but is associated with a different log. Recreating source." -Level "WARNING"
                Remove-EventLog -Source $SourceName
                New-EventLog -LogName $LogName -Source $SourceName
                Write-EnhancedLog -Message "Source '$SourceName' was associated with a different log ('$ValidationResult.SourceLogName'). Recreated event log '$LogName' with source '$SourceName'." -Level "WARNING"
            }
            elseif (-not $ValidationResult.LogExists -and $ValidationResult.SourceExists) {
                # Source exists but is associated with a different log, so remove the source and create the correct log and source
                Write-EnhancedLog -Message "Log does not exist, but source exists. Removing source and creating log." -Level "WARNING"
                Remove-EventLog -Source $SourceName
                New-EventLog -LogName $LogName -Source $SourceName
                Write-EnhancedLog -Message "Event source '$SourceName' was associated with a different log. Recreated event log '$LogName' with source '$SourceName'." -Level "WARNING"
            }
            elseif ($ValidationResult.LogExists -and -not $ValidationResult.SourceExists) {
                # Log exists but the source does not, so create the source
                Write-EnhancedLog -Message "Log exists, but source does not. Creating source." -Level "INFO"
                New-EventLog -LogName $LogName -Source $SourceName
                Write-EnhancedLog -Message "Added source '$SourceName' to existing event log '$LogName'." -Level "INFO"
            }
            else {
                # Both log and source exist and are correctly associated
                Write-EnhancedLog -Message "Event log '$LogName' and source '$SourceName' already exist and are correctly associated." -Level "INFO"
            }

            $DBG
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Manage-EventLogSource function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Manage-EventLogSource function" -Level "NOTICE"
    }
}

function Sanitize-ParentScriptName {
    <#
    .SYNOPSIS
    Sanitizes the parent script name by removing spaces and any special characters.

    .DESCRIPTION
    The Sanitize-ParentScriptName function ensures that the parent script name is sanitized by removing spaces, special characters, and ensuring it conforms to naming conventions suitable for log names.

    .PARAMETER ParentScriptName
    The parent script name to sanitize.

    .EXAMPLE
    $sanitizedParentScriptName = Sanitize-ParentScriptName -ParentScriptName "My Script Name 2024"
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ParentScriptName
    )

    Begin {
        Write-EnhancedLog -Message "Starting Sanitize-ParentScriptName function" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Remove any spaces and special characters
            Write-EnhancedLog -Message "Sanitizing the parent script name: '$ParentScriptName'." -Level "INFO"
            $sanitizedParentScriptName = $ParentScriptName -replace '\s+', '' -replace '[^a-zA-Z0-9]', ''
            Write-EnhancedLog -Message "Sanitized parent script name: '$sanitizedParentScriptName'." -Level "INFO"

            return $sanitizedParentScriptName
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Sanitize-ParentScriptName function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Sanitize-ParentScriptName function" -Level "NOTICE"
    }
}

function Sanitize-LogName {
    <#
    .SYNOPSIS
    Sanitizes the log name to ensure it is a valid string.

    .DESCRIPTION
    The Sanitize-LogName function checks if the log name is a valid string. If the log name is not a string, the function attempts to convert it. If it contains invalid characters or if the conversion is not possible, an error is thrown.

    .PARAMETER LogName
    The log name to sanitize.

    .EXAMPLE
    $sanitizedLogName = Sanitize-LogName -LogName $logName
    Sanitizes the provided log name and returns a clean string.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [System.Object]$LogName
    )

    Begin {
        Write-EnhancedLog -Message "Starting Sanitize-LogName function" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Ensure the LogName is a single string, not an array or hashtable
            if ($LogName -is [System.Collections.IEnumerable] -and $LogName -notlike [string]) {
                Write-EnhancedLog -Message "Log name is an array or collection. Attempting to extract the first valid string." -Level "WARNING"
                $LogName = $LogName | Where-Object { $_ -is [string] } | Select-Object -First 1
            }

            # If LogName is still not a string, throw an error
            if ($LogName -isnot [string]) {
                Write-EnhancedLog -Message "Log name is not a valid string. Actual type: $($LogName.GetType().Name)" -Level "ERROR"
                throw "Log name must be a string. Received type: $($LogName.GetType().Name)"
            }

            # Sanitize the log name by trimming and removing any unnecessary characters
            $sanitizedLogName = $LogName.Trim() -replace '[^\w-]', ''
            Write-EnhancedLog -Message "Sanitized log name: '$sanitizedLogName'" -Level "INFO"

            return $sanitizedLogName
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Sanitize-LogName function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Sanitize-LogName function" -Level "NOTICE"
    }
}

function Sanitize-SourceName {
    <#
    .SYNOPSIS
    Sanitizes the source name by removing spaces and special characters.

    .DESCRIPTION
    The Sanitize-SourceName function ensures that the source name is sanitized by removing spaces, special characters, and ensuring it conforms to naming conventions suitable for log sources.

    .PARAMETER SourceName
    The source name to sanitize.

    .EXAMPLE
    $sanitizedSourceName = Sanitize-SourceName -SourceName "My Source Name 2024"
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceName
    )

    Begin {
        Write-EnhancedLog -Message "Starting Sanitize-SourceName function" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Remove any spaces and special characters
            Write-EnhancedLog -Message "Sanitizing the source name: '$SourceName'." -Level "INFO"
            $sanitizedSourceName = $SourceName -replace '\s+', '' -replace '[^a-zA-Z0-9]', ''
            Write-EnhancedLog -Message "Sanitized source name: '$sanitizedSourceName'." -Level "INFO"

            return $sanitizedSourceName
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Sanitize-SourceName function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Sanitize-SourceName function" -Level "NOTICE"
    }
}

function Manage-EventLogs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ParentScriptName
    )

    Begin {
        Write-EnhancedLog -Message "Starting Manage-EventLogs function" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Step 1: Sanitize the parent script name
            Write-EnhancedLog -Message "Sanitizing the parent script name." -Level "INFO"
            $sanitizedParentScriptName = Sanitize-ParentScriptName -ParentScriptName $ParentScriptName
            Write-EnhancedLog -Message "Sanitized parent script name: '$sanitizedParentScriptName'." -Level "INFO"

            # Step 2: Generate the unique base for the log name
            Write-EnhancedLog -Message "Generating unique base for log name." -Level "INFO"
            $uniqueBase = Generate-UniqueBase
            Write-EnhancedLog -Message "Unique base generated: $uniqueBase" -Level "INFO"

            # Step 3: Combine the unique base with the sanitized parent script name
            $logName = "$uniqueBase-$sanitizedParentScriptName"
            Write-EnhancedLog -Message "Constructed log name: $logName" -Level "INFO"

            # Step 4: Sanitize the log name
            Write-EnhancedLog -Message "Sanitizing the log name." -Level "INFO"
            $global:sanitizedlogName = Sanitize-LogName -LogName $logName
            Write-EnhancedLog -Message "Sanitized log name: '$global:sanitizedlogName'." -Level "INFO"

            # Step 5: Retrieve existing logs matching the sanitized parent script name
            Write-EnhancedLog -Message "Retrieving existing logs that match the sanitized parent script name: '$sanitizedParentScriptName'." -Level "INFO"
            $logs = @()
            try {
                $logs = @(Get-WinEvent -ListLog * | Where-Object { $_.LogName -like "*$sanitizedParentScriptName*" })
                Write-EnhancedLog -Message "Retrieved $($logs.Count) logs that match the sanitized parent script name." -Level "INFO"
            }
            catch {
                Write-EnhancedLog -Message "Failed to retrieve logs due to an error: $($_.Exception.Message)" -Level "ERROR"
                throw $_
            }

            # Step 6: Check if an existing log should be used
            if ($logs.Count -gt 0) {
                $existingLog = $logs | Select-Object -First 1
                if ($existingLog) {
                    $logName = $existingLog.LogName
                    Write-EnhancedLog -Message "Existing log found and will be used: '$logName'." -Level "INFO"
                }
            }
            else {
                Write-EnhancedLog -Message "No existing log found for sanitized parent script name: '$sanitizedParentScriptName'. Creating a new log: '$logName'." -Level "INFO"
            }

            # Return the sanitized and validated log name
            return $logName
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Manage-EventLogs function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Manage-EventLogs function" -Level "NOTICE"
    }
}

function Construct-SourceName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogName,

        [Parameter(Mandatory = $true)]
        [string]$CallerFunction
    )

    Begin {
        Write-EnhancedLog -Message "Starting Construct-SourceName function" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Step 1: Construct the initial source name
            Write-EnhancedLog -Message "Constructing source name using LogName '$LogName' and CallerFunction '$CallerFunction'." -Level "INFO"
            $sourceName = "$LogName-$CallerFunction"
            Write-EnhancedLog -Message "Constructed source name: '$sourceName'" -Level "INFO"

            # Step 2: Sanitize the source name
            Write-EnhancedLog -Message "Sanitizing the constructed source name." -Level "INFO"
            $sanitizedSourceName = Sanitize-SourceName -SourceName $sourceName
            Write-EnhancedLog -Message "Sanitized source name: '$sanitizedSourceName'." -Level "INFO"

            return $sanitizedSourceName
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Construct-SourceName function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Construct-SourceName function" -Level "NOTICE"
    }
}
function Initialize-EventLog {
    <#
    .SYNOPSIS
    Initializes the event log by managing logs, validating before and after operations, and managing sources.

    .DESCRIPTION
    The Initialize-EventLog function handles the entire process of setting up an event log. It manages the creation or retrieval of logs, validates them before and after operations, and ensures the correct association of event sources.

    .PARAMETER SourceName
    The name of the event source to be used.

    .PARAMETER ParentScriptName
    The name of the parent script to be used as part of the event log name.

    .EXAMPLE
    Initialize-EventLog -SourceName "MySource" -ParentScriptName "MyScript"
    Initializes an event log with the specified source and parent script name.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceName,

        [Parameter(Mandatory = $true)]
        [string]$ParentScriptName
    )

    Begin {
        Write-EnhancedLog -Message "Starting Initialize-EventLog function" -Level "WARNING"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Step 1: Manage Logs
            Write-EnhancedLog -Message "Managing event logs." -Level "INFO"
            try {
                Write-EnhancedLog -Message "Calling Manage-EventLogs function with ParentScriptName: '$ParentScriptName'." -Level "DEBUG"
                $global:sanitizedlogName = Manage-EventLogs -ParentScriptName $ParentScriptName
                Write-EnhancedLog -Message "Manage-EventLogs function returned log name: '$global:sanitizedlogName'." -Level "INFO"
            }
            catch {
                Write-EnhancedLog -Message "An error occurred while managing event logs: $($_.Exception.Message)" -Level "ERROR"
                throw $_
            }

            $DBG

            # Step 2: Sanitize the Log Name
            try {
                Write-EnhancedLog -Message "Sanitizing the log name returned by Manage-EventLogs." -Level "INFO"
                $global:sanitizedlogName = Sanitize-LogName -LogName $global:sanitizedlogName
                Write-EnhancedLog -Message "Sanitized log name: '$global:sanitizedlogName'." -Level "INFO"
            }
            catch {
                Write-EnhancedLog -Message "An error occurred while sanitizing the log name: $($_.Exception.Message)" -Level "ERROR"
                throw $_
            }

            # Step 3: Construct the source name using the sanitized log name and the caller function
            try {
                Write-EnhancedLog -Message "Constructing the source name using the sanitized log name and caller function." -Level "INFO"
                $global:sanitizedsourceName = Construct-SourceName -LogName $global:sanitizedlogName -CallerFunction $SourceName
                Write-EnhancedLog -Message "Constructed source name: '$global:sanitizedsourceName'." -Level "INFO"
            }
            catch {
                Write-EnhancedLog -Message "An error occurred while constructing the source name: $($_.Exception.Message)" -Level "ERROR"
                throw $_
            }

            $DBG




            # Step 4: Pre-Validation
            Write-EnhancedLog -Message "Performing pre-validation for log '$global:sanitizedlogName' and source '$global:sanitizedsourceName'." -Level "INFO"
            try {
                $validationResult = Validate-EventLog -LogName $global:sanitizedlogName -SourceName $global:sanitizedsourceName
                Write-EnhancedLog -Message "Pre-validation completed: Log exists = $($validationResult.LogExists), Source exists = $($validationResult.SourceExists)." -Level "INFO"
            }
            catch {
                Write-EnhancedLog -Message "An error occurred during pre-validation: $($_.Exception.Message)" -Level "ERROR"
                throw $_
            }

            $DBG

            # Step 5: Manage Sources
            Write-EnhancedLog -Message "Managing event log sources for log '$global:sanitizedlogName' and source '$global:sanitizedsourceName'." -Level "INFO"
            try {
                Manage-EventLogSource -LogName $global:sanitizedlogName -SourceName $global:sanitizedsourceName -ValidationResult $validationResult
                Write-EnhancedLog -Message "Event log sources managed successfully." -Level "INFO"
            }
            catch {
                Write-EnhancedLog -Message "An error occurred while managing event log sources: $($_.Exception.Message)" -Level "ERROR"
                throw $_
            }

            $DBG

            # Step 6: Post-Validation (Optional)
            Write-EnhancedLog -Message "Performing post-validation for log '$global:sanitizedlogName' and source '$global:sanitizedsourceName'." -Level "INFO"
            try {
                Validate-EventLog -LogName $global:sanitizedlogName -SourceName $global:sanitizedsourceName -PostValidation
                Write-EnhancedLog -Message "Post-validation completed successfully." -Level "INFO"
            }
            catch {
                Write-EnhancedLog -Message "An error occurred during post-validation: $($_.Exception.Message)" -Level "ERROR"
                throw $_
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Initialize-EventLog function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }

        $DBG
    }

    End {
        Write-EnhancedLog -Message "Preparing to exit Initialize-EventLog function. Returning log name: '$global:sanitizedlogName'." -Level "INFO"

        # Ensure that only the log name string is returned
        try {
            if (-not $global:sanitizedlogName) {
                throw "Log name is null or empty. Cannot return a valid log name."
            }

            # Log the type of logName to ensure it's a string
            if ($global:sanitizedlogName -isnot [string]) {
                Write-EnhancedLog -Message "Log name is not a string. Actual type: $($global:sanitizedlogName.GetType().Name)" -Level "ERROR"
                throw "Unexpected type for log name. Expected string."
            }

            Write-EnhancedLog -Message "Log name '$global:sanitizedlogName' is valid and will be returned." -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while finalizing the log name: $($_.Exception.Message)" -Level "ERROR"
            throw $_
        }

        $DBG

        Write-EnhancedLog -Message "Exiting Initialize-EventLog function" -Level "WARNING"
        return $global:sanitizedlogName
    }
}
function Write-LogMessage {
    <#
    .SYNOPSIS
    Writes a log message to the event log with a specified level and event ID.

    .DESCRIPTION
    The Write-LogMessage function writes a message to the event log. It maps custom levels to event log entry types and event IDs, determines the calling function, and ensures the event log and source are properly initialized.

    .PARAMETER Message
    The message to write to the event log.

    .PARAMETER Level
    The level of the message, which determines the event log entry type. Defaults to 'INFO'.

    .PARAMETER EventID
    The event ID for the log entry. Defaults to 1000.

    .EXAMPLE
    Write-LogMessage -Message "This is a test log message" -Level "ERROR" -EventID 3001
    Writes an error message to the event log with event ID 3001.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Level = 'INFO',

        [Parameter(Mandatory = $false)]
        [int]$EventID = 1000
    )

    Begin {
        Write-EnhancedLog -Message "Starting Write-LogMessage function" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Get the PowerShell call stack to determine the actual calling function
            Write-EnhancedLog -Message "Retrieving the PowerShell call stack to determine the caller function." -Level "DEBUG"
            $callStack = Get-PSCallStack
            $callerFunction = if ($callStack.Count -ge 2) { $callStack[1].Command } else { '<Unknown>' }
            Write-EnhancedLog -Message "Caller function identified as '$callerFunction'." -Level "INFO"

            # Map custom levels to event log entry types and event IDs
            Write-EnhancedLog -Message "Mapping log level '$Level' to entry type and event ID." -Level "INFO"
            $entryType, $mappedEventID = switch ($Level.ToUpper()) {
                'DEBUG' { 'Information', 1001 }
                'INFO' { 'Information', 1002 }
                'NOTICE' { 'Information', 1003 }
                'WARNING' { 'Warning', 2001 }
                'ERROR' { 'Error', 3001 }
                'CRITICAL' { 'Error', 3002 }
                'IMPORTANT' { 'Information', 1004 }
                'OUTPUT' { 'Information', 1005 }
                'SIGNIFICANT' { 'Information', 1006 }
                'VERYVERBOSE' { 'Information', 1007 }
                'VERBOSE' { 'Information', 1008 }
                'SOMEWHATVERBOSE' { 'Information', 1009 }
                'SYSTEM' { 'Information', 1010 }
                'INTERNALCOMMENT' { 'Information', 1011 }
                default { 'Information', 9999 }
            }
            Write-EnhancedLog -Message "Log level '$Level' mapped to entry type '$entryType' and event ID '$mappedEventID'." -Level "INFO"

            # Use provided EventID if specified, otherwise use mapped EventID
            $eventID = if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('EventID')) { $EventID } else { $mappedEventID }
            Write-EnhancedLog -Message "Using Event ID: $eventID" -Level "INFO"

            # Ensure the event log and source are initialized
            Write-EnhancedLog -Message "Initializing event log for source '$callerFunction'." -Level "INFO"

            $DBG
            try {
                Write-EnhancedLog -Message "Calling Initialize-EventLog function with SourceName: '$callerFunction'." -Level "INFO"
                $global:sanitizedlogName = Initialize-EventLog -SourceName $callerFunction -ParentScriptName $ParentScriptName
                Write-EnhancedLog -Message "Event log initialized with name '$global:sanitizedlogName'." -Level "INFO"
            
                # Sanitize the log name
                Write-EnhancedLog -Message "Sanitizing the log name for source '$callerFunction'." -Level "INFO"
                $global:sanitizedlogName = Sanitize-LogName -LogName $global:sanitizedlogName
                Write-EnhancedLog -Message "Sanitized log name: '$global:sanitizedlogName'." -Level "INFO"
            
                $DBG
            }
            catch {
                Write-EnhancedLog -Message "Failed to initialize or sanitize event log for source '$callerFunction': $($_.Exception.Message)" -Level "ERROR"
                Handle-Error -ErrorRecord $_
                throw $_
            }
            
            $DBG

            # Validate the log name before writing to the event log
            if (-not $global:sanitizedlogName -or $global:sanitizedlogName -is [System.Collections.Hashtable]) {
                Write-EnhancedLog -Message "The log name '$global:sanitizedlogName' is invalid or is a hashtable. Halting operation." -Level "CRITICAL"
                throw "Invalid log name: '$global:sanitizedlogName'"
            }

            $DBG

            # Write the message to the specified event log
            try {
                Write-EnhancedLog -Message "Validating if the event log source '$global:sanitizedsourceName' exists in log '$global:sanitizedlogName'." -Level "INFO"
                
                # Check if the source exists and count occurrences
          
            
                try {
                    # Check if the source exists and count occurrences
                    Write-EnhancedLog -Message "Checking if event log source '$global:sanitizedsourceName' exists in log '$global:sanitizedlogName'." -Level "INFO"
                    
                    $sourceExists = [System.Diagnostics.EventLog]::SourceExists("$global:sanitizedsourceName")
                    
                    if ($sourceExists) {
                        Write-EnhancedLog -Message "Event log source '$global:sanitizedsourceName' exists. Retrieving log name associated with the source." -Level "INFO"
                        
                        try {
                            $sourceLogName = [System.Diagnostics.EventLog]::LogNameFromSourceName("$global:sanitizedsourceName", ".")
                            Write-EnhancedLog -Message "Associated log name retrieved: '$sourceLogName'." -Level "INFO"
                            
                            try {
                                # Count occurrences of the source in the log
                                $sourceCount = @(Get-EventLog -LogName $sourceLogName -Source "$global:sanitizedsourceName").Count
                            
                                if ($sourceCount -eq 0) {
                                    Write-EnhancedLog -Message "No previous events found for source '$global:sanitizedsourceName' in log '$sourceLogName'. This is the first event being logged for this source." -Level "INFO"
                                }
                                else {
                                    Write-EnhancedLog -Message "Number of occurrences for source '$global:sanitizedsourceName' in log '$sourceLogName': $sourceCount." -Level "INFO"
                                }
                            }
                            catch {
                                Write-EnhancedLog -Message "Failed to count occurrences of source '$global:sanitizedsourceName' in log '$sourceLogName': $($_.Exception.Message)" -Level "ERROR"
                                throw $_
                            }
                            
                        }
                        catch {
                            Write-EnhancedLog -Message "Failed to retrieve the log name associated with the source '$global:sanitizedsourceName': $($_.Exception.Message)" -Level "ERROR"
                            throw $_
                        }
                    }
                    else {
                        Write-EnhancedLog -Message "Event log source '$global:sanitizedsourceName' does not exist in log '$global:sanitizedlogName'. Proceeding to create it." -Level "WARNING"
                    }
                }
                catch {
                    Write-EnhancedLog -Message "An error occurred while checking or counting occurrences of the event log source '$global:sanitizedsourceName': $($_.Exception.Message)" -Level "ERROR"
                    Handle-Error -ErrorRecord $_
                    throw $_
                }
                

                $DBG
                Write-EnhancedLog -Message "Writing log message to event log '$global:sanitizedlogName' for source '$global:sanitizedsourceName'." -Level "INFO"
                Write-EventLog -LogName $global:sanitizedlogName -Source "$global:sanitizedsourceName" -EntryType $entryType -EventId $eventID -Message $Message
                Write-Host "Logged message to '$global:sanitizedlogName' from source '$global:sanitizedsourceName'"
            }
            catch {
                Write-EnhancedLog -Message "Failed to write log message to event log '$global:sanitizedlogName' for source '$global:sanitizedsourceName': $($_.Exception.Message)" -Level "ERROR"
                throw $_
            }
            

            $DBG
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Write-LogMessage function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Write-LogMessage function" -Level "NOTICE"
    }
}


# Example function to demonstrate logging
function ExampleFunction {
    Write-LogMessage -Message "This is a test message from ExampleFunction." -Level "INFO"
}

# Call the function to generate a log entry
ExampleFunction



function ExampleFunction2 {
    Write-LogMessage -Message "This is a test message from ExampleFunction2." -Level "ERROR"
}

# Call the function to generate a log entry
# ExampleFunction2

# Verify the log in Event Viewer or use Get-WinEvent
# Get-WinEvent -LogName 'AppLog10' -MaxEvents 10

if ($global:sanitizedlogName) {
    try {
        Write-Host "Attempting to retrieve the last 10 events from the log '$global:sanitizedlogName'."
        $events = Get-WinEvent -LogName $global:sanitizedlogName -MaxEvents 10
        if ($events.Count -gt 0) {
            Write-Host "Successfully retrieved the last 10 events from the log '$global:sanitizedlogName'."
            $events | Format-Table -AutoSize
        }
        else {
            Write-Warning "No events found in the log '$global:sanitizedlogName'."
        }
    }
    catch {
        Write-Error "Failed to retrieve events from the log '$global:sanitizedlogName'. Error: $_"
    }
}
else {
    Write-Warning "Log name not found. Please initialize it first."
}



# Writing to AppLog7
# Write-LogMessage -LogName "AppLog6" -SourceName "AppSource6" -Message "Message from AppSource6 in AppLog9"

# # Writing to AppLog8
# Write-LogMessage -LogName "AppLog8" -SourceName "AppSource8" -Message "Message from AppSource8 in AppLog8"


# Writing different types of messages
# Write-LogMessage -LogName "AppLog1" -SourceName "AppSource1" -Message "This is a debug message." -Level "DEBUG"
# Write-LogMessage -LogName "AppLog1" -SourceName "AppSource1" -Message "This is an informational message." -Level "INFO"
# Write-LogMessage -LogName "AppLog1" -SourceName "AppSource1" -Message "This is a warning message." -Level "WARNING"
# Write-LogMessage -LogName "AppLog1" -SourceName "AppSource1" -Message "This is an error message." -Level "ERROR"
# Write-LogMessage -LogName "AppLog1" -SourceName "AppSource1" -Message "This is a critical error message." -Level "CRITICAL"


# Check logs for AppLog7
# Get-WinEvent -LogName "AppLog6" -MaxEvents 10

# # Check logs for AppLog8
# Get-WinEvent -LogName "AppLog8" -MaxEvents 10

# Get-WinEvent -LogName "AppLog1" -MaxEvents 10



