param(
    [switch]$Delete
)
# Load required assemblies
Add-Type -AssemblyName System.Web

# === CONFIGURATION ===
$Username = "root"
$Password = "root"
$ServerUrl = "http://localhost"
$LocalUrl = "http://localhost"
$ApiEndpoint = "/server/api/v3/database/query"
# Create timestamp for unique filenames
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$OutputFile = "DuplicateFiles_Report_$Timestamp.csv"
$BreadcrumbExtension = ".breadcrumb.txt"  # Extension for breadcrumb files
$DeletionLogFile = "DuplicateFiles_Deletions_$Timestamp.log" # Log file for tracking deletions

# Confirmation for deletion
$PerformDeletion = $false
if ($Delete) {
    $confirmation = Read-Host "Are you sure you want to delete duplicate files and leave breadcrumbs? Type Y to confirm"
    if ($confirmation -eq 'Y') {
        $PerformDeletion = $true
    } else {
        Write-Host "Deletion cancelled by user. No files will be deleted." -ForegroundColor Yellow
    }
}

# Search settings
$SearchDirectory = "/MC-Legion Aggregator-Collector/File System/C:/Aparavi/Data/Demo/"
$LimitResults = 10 

# Format the directory path for query
$SearchPath = $SearchDirectory.TrimEnd('/') + "/%"

# === CREATE AUTH HEADER ===
$Pair = "${Username}:${Password}"
$Bytes = [System.Text.Encoding]::ASCII.GetBytes($Pair)
$Base64 = [System.Convert]::ToBase64String($Bytes)
$Headers = @{ Authorization = "Basic $Base64" }

# === QUERY OPTIONS ===
$Options = "{`"format`":`"csv`",`"stream`":true}"
$OptionsEncoded = [System.Web.HttpUtility]::UrlEncode($Options)

# === STEP 1: Get all duplicate keys from the specified directory ===
$Query1 = @"
SELECT 
  dupKey
WHERE 
  parentPath LIKE '$SearchPath' 
  AND dupKey > 1
LIMIT $LimitResults
"@

# Ensure proper URL encoding of query parameters
$QueryEncoded = [System.Web.HttpUtility]::UrlEncode($Query1)
$Url1 = "$ServerUrl$ApiEndpoint" + "?select=$QueryEncoded&options=$OptionsEncoded"
Write-Host "Fetching duplicate keys from $SearchDirectory..."
$DupKeysCSV = Invoke-RestMethod -Uri $Url1 -Headers $Headers -Method GET

# Parse the CSV to get duplicate keys
$DupKeys = ConvertFrom-Csv -InputObject $DupKeysCSV

# Filter to ensure unique dupKeys only
$UniqueKeys = @{}
$UniqueDupKeys = @()
foreach ($DupKeyObj in $DupKeys) {
    $DupKey = $DupKeyObj.dupKey
    if (-not [string]::IsNullOrWhiteSpace($DupKey) -and -not $UniqueKeys.ContainsKey($DupKey)) {
        $UniqueKeys[$DupKey] = $true
        $UniqueDupKeys += $DupKeyObj
    }
}

Write-Host "Found $(($DupKeys | Measure-Object).Count) total duplicate keys, filtered to $(($UniqueDupKeys | Measure-Object).Count) unique keys."

# Create a file to store the final results
"File Name,Duplicate Count,Parent Path,Duplicate Key,Local Path" | Out-File -FilePath $OutputFile

# === STEP 2: For each duplicate key, find all instances ===
$Counter = 0
$Total = ($UniqueDupKeys | Measure-Object).Count

foreach ($DupKeyObj in $UniqueDupKeys) {
    $Counter++
    $DupKey = $DupKeyObj.dupKey
    
    # Progress update
    Write-Progress -Activity "Processing duplicate files" -Status "Processing group $Counter of $Total" -PercentComplete (($Counter / $Total) * 100)
    
    # Skip if empty (header row)
    if ([string]::IsNullOrWhiteSpace($DupKey)) { continue }
    
    # Build the query to find all instances of this duplicate key
    $Query2 = @"
SELECT
name,
parentPath,
dupKey,
localPath
WHERE
dupKey = '$DupKey'
LIMIT 25000
"@
    
    # Query for all instances of this duplicate key
    $QueryEncoded = [System.Web.HttpUtility]::UrlEncode($Query2)
    $Url2 = "$LocalUrl$ApiEndpoint" + "?select=$QueryEncoded&options=$OptionsEncoded"
    # Write-Host "Detail URL: $Url2"  # Removed from logs
    
    try {
        $DupFilesCSV = Invoke-RestMethod -Uri $Url2 -Headers $Headers -Method GET
        $DupFiles = ConvertFrom-Csv -InputObject $DupFilesCSV
        
        # Count the duplicates
        $DuplicateCount = $DupFiles.Count
        
        # Add to the results file
        foreach ($File in $DupFiles) {
            $SanitizedLocalPath = $File.localPath -replace "^File System/", ""
            "$($File.name),$DuplicateCount,$($File.parentPath),$($File.dupKey),$SanitizedLocalPath" | Out-File -FilePath $OutputFile -Append
        }

        # Handle duplicate file cleanup if enabled
        if ($PerformDeletion -and $DuplicateCount -gt 1) {
            # Find files in the original search directory
            $OriginalFolder = $SearchDirectory.TrimEnd('/')
            $OriginalFile = $DupFiles | Where-Object { $_.parentPath.StartsWith($OriginalFolder) } | Select-Object -First 1
            
            # If no file in the original directory is found, use the first file as the original
            if ($null -eq $OriginalFile) {
                $OriginalFile = $DupFiles[0]
                Write-Host "No file found in original directory. Using first file as original: $($OriginalFile.parentPath)$($OriginalFile.name)" -ForegroundColor Yellow
            }
            
            $OriginalPath = "$($OriginalFile.parentPath)$($OriginalFile.name)"
            Write-Host "Original file: $OriginalPath" -ForegroundColor Green
            
            # Delete duplicates and create breadcrumb files
            foreach ($File in $DupFiles) {
                # Skip the original file
                if ($File.parentPath + $File.name -eq $OriginalFile.parentPath + $OriginalFile.name) {
                    continue
                }

                $SanitizedLocalPath = $File.localPath -replace "^File System/", ""
                $BreadcrumbPath = "$SanitizedLocalPath$BreadcrumbExtension"

                Write-Host "Deleting duplicate: $SanitizedLocalPath" -ForegroundColor Yellow

                # Create breadcrumb file
                $BreadcrumbContent = @"
This is a breadcrumb file indicating that a duplicate file was removed.
Original file: $OriginalPath
Duplicate file that was here: $SanitizedLocalPath
Duplicate key: $($File.dupKey)
Removed on: $(Get-Date)
"@
                $BreadcrumbContent | Out-File -FilePath $BreadcrumbPath -Force

                # Log the deletion
                "$(Get-Date) - DELETED: $SanitizedLocalPath - ORIGINAL: $OriginalPath - BREADCRUMB: $BreadcrumbPath" | Out-File -FilePath $DeletionLogFile -Append

                # Actually delete the file (commented out for safety - uncomment when ready)
                # Remove-Item -Path $SanitizedLocalPath -Force
            }
        }
        
        Write-Host "Processed duplicate key: $($DupKey.Substring(0, [Math]::Min(20, $DupKey.Length)))... ($($DupFiles.Count) duplicates)"
    }
    catch {
        Write-Host "Error processing duplicate key: $DupKey" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

Write-Host "Export complete. Report saved to $OutputFile"
Write-Host "Duplicates are grouped by their common 'Duplicate Key' value."