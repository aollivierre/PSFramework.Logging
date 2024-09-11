# Usage Example: Logging and Retrieving Events Across USER and SYSTEM Contexts
# This example demonstrates how to create an event log in the USER context and later retrieve it in the SYSTEM context using the functions provided earlier.

# Step 1: USER Script
# The USER script creates an event log and stores the log name in the registry, allowing the SYSTEM script to retrieve and access it.


# User Script: Create and Save Event Log Name

# Assume $logName is dynamically generated elsewhere in the script
$logName = "13075842-PSFrameworkloggingEventLogModulecopy18"

# Save the log name to the registry
Save-LogNameToRegistry -LogName $logName

# Write a test event to the log
Write-EventLog -LogName $logName -Source "UserScriptExample" -EntryType Information -EventId 1001 -Message "User script has initialized the event log."

Write-Host "Event log '$logName' created and saved in the registry."


# Step 2: SYSTEM Script
# The SYSTEM script retrieves the log name from the registry and reads the last 10 events from that log.


# System Script: Retrieve and Read Event Log

# Retrieve the log name from the registry
$logName = Get-LogNameFromRegistry

if ($logName) {
    # Retrieve and display the last 10 events from the event log
    Retrieve-LogEvents
} else {
    Write-Host "Failed to retrieve log name from the registry. Ensure the USER script has run and stored the log name."
}
# Detailed Workflow:
# USER Script Execution:

# The USER script generates an event log name ($logName) and writes it to the registry using Save-LogNameToRegistry.
# The script then writes an initial event to the log using Write-EventLog.
# This log name is now stored in a registry key accessible by SYSTEM and USER contexts.
# SYSTEM Script Execution:

# The SYSTEM script retrieves the log name from the registry using Get-LogNameFromRegistry.
# If the log name is retrieved successfully, the script calls Retrieve-LogEvents to fetch and display the last 10 events from that log.
# Expected Output:
# When the SYSTEM script runs after the USER script has initialized the log, it should successfully retrieve and display the last 10 events from the event log, including the event created by the USER script.

# Example Output:

# plaintext
# Copy code
# Log name retrieved: 13075842-PSFrameworkloggingEventLogModulecopy18
# Attempting to retrieve the last 10 events from the log '13075842-PSFrameworkloggingEventLogModulecopy18'.
# Successfully retrieved the last 10 events from the log '13075842-PSFrameworkloggingEventLogModulecopy18'.
# Key Considerations:
# Registry Path: Ensure the registry path used in Save-LogNameToRegistry and Get-LogNameFromRegistry is consistent and accessible by both contexts.
# Permissions: The use of HKLM:\SOFTWARE\MyApp\Logging ensures that both SYSTEM and USER have the necessary permissions to access the log name.
# This approach ensures that the SYSTEM script can dynamically retrieve and use the event log created by the USER script without running into permission issues or needing to hardcode log names.