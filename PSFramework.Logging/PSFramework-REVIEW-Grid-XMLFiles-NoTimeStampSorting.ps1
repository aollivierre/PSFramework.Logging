# Define the path to the folder containing the XML files
$folderPath = "C:\Logs\PSF\2024-10-02\Handle.PSF.Logging.test"

# Get all XML files in the folder
$xmlFiles = Get-ChildItem -Path $folderPath -Filter "*.xml"

# Initialize an array to store results
$allResults = @()

# Loop through each XML file and extract relevant data
foreach ($file in $xmlFiles) {
    # Load the XML content
    $xml = [xml](Get-Content -Path $file.FullName)

    # Extract the relevant data
    $results = $xml.Objs.Obj.Props | ForEach-Object {
        [PSCustomObject]@{
            ExceptionMessage = $_.S | Where-Object { $_.N -eq "Message" } | Select-Object -ExpandProperty '#text'
            FunctionName     = $_.S | Where-Object { $_.N -eq "FunctionName" } | Select-Object -ExpandProperty '#text'
            ModuleName       = $_.S | Where-Object { $_.N -eq "ModuleName" } | Select-Object -ExpandProperty '#text'
            Timestamp        = $_.DT | Where-Object { $_.N -eq "Timestamp" } | Select-Object -ExpandProperty '#text'
            ComputerName     = $_.S | Where-Object { $_.N -eq "ComputerName" } | Select-Object -ExpandProperty '#text'
            FileName         = $file.Name  # Add the filename for context
        }
    }

    # Add the results to the array
    $allResults += $results
}

# Display all results in Out-GridView
$allResults | Out-GridView
