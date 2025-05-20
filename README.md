# Aparavi Duplicate File Tool

> **⚠️ The Aparavi Data Suite is required for this tool to function.**
> 
> Please ensure you have access to an Aparavi environment and that it is running before using this tool.

A PowerShell tool for identifying and reporting duplicate files in Aparavi data management systems. This utility leverages Aparavi's API to find files with identical content (same dupKey) and generate CSV reports for analysis.

## Requirements

- PowerShell 5.1 or higher
- **Aparavi Data Suite (with API access) is required**
- Basic authentication credentials for the Aparavi API

## Configuration

The script uses the following configuration parameters at the top of the `DuplicateTool.ps1` file:

```powershell
# === CONFIGURATION ===
$Username = "root"             # Aparavi API username
$Password = "root"             # Aparavi API password
$ServerUrl = "http://localhost" # Aparavi server URL
$LocalUrl = "http://localhost"  # Local URL for API access
$ApiEndpoint = "/server/api/v3/database/query" # API endpoint path
# Create timestamp for unique filenames
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$OutputFile = "DuplicateFiles_Report_$Timestamp.csv"    # Output report filename with timestamp

# Search settings
$SearchDirectory = "/MC-Legion Aggregator-Collector/File System/C:/Aparavi/Data/Demo/" # Directory to search
$LimitResults = 100           # Limit the number of duplicate key groups to process

# Cleanup parameters
$BreadcrumbExtension = ".breadcrumb.txt"  # Extension for breadcrumb files
$DeletionLogFile = "DuplicateFiles_Deletions_$Timestamp.log" # Log file for tracking deletions

# Script Versions
- **DuplicateTool-Delete.ps1**: Main script. Generates a duplicate file report and, if the `-Delete` parameter is provided, prompts for confirmation and then deletes duplicate files and leaves breadcrumb files.
- **DuplicateTool.ps1**: Safe script. Only generates the duplicate file report. No files are deleted and no breadcrumbs are created.

# Script Parameters (DuplicateTool-Delete.ps1)
- `-Delete` (optional): If provided, the script will prompt for confirmation and, if confirmed, will delete duplicate files and leave breadcrumbs. If not provided, the script only generates the report.
```

Update these values to match your Aparavi environment before running the script.

## How It Works

The script operates in two main steps:

1. **Find Duplicate Keys**: Queries Aparavi's API to find all unique `dupKey` values for files in the specified directory that have duplicates (dupKey > 1).

2. **Get File Details**: For each unique duplicate key found, it queries the API again to retrieve detailed information about all files sharing that key.

3. **Export Report**: Exports a timestamped CSV report containing file names, duplicate counts, parent paths, and duplicate keys for all identified duplicate files.

The script includes an optional duplicate cleanup feature that can:

1. Identify the "original" file from each duplicate group (files in the main search directory are considered originals)
2. Remove duplicate files from other locations
3. Create breadcrumb text files in place of removed duplicates that point to the original file
4. Log all deletions to a timestamped log file for auditing purposes

To enable this feature:

1. Set `$CleanupDuplicates = $true` in the script
2. If needed, customize the `$BreadcrumbExtension` for the breadcrumb files

## Key Features

- **Timestamped Reports**: Each run creates a uniquely timestamped report to prevent overwriting previous results
- **Duplicate Filtering**: The script ensures each duplicate key is processed only once, eliminating redundant API calls
- **Progress Tracking**: Shows completion percentage and details about each group of duplicates as they're processed
- **Error Handling**: Includes robust error handling for API request failures

## Usage

### Generate a Report (No Deletions)

> **Note:** The Aparavi Data Suite must be installed, running, and accessible before executing the script. The tool communicates with your Aparavi environment via its API.

To generate a CSV report of duplicate files **without deleting anything**, use the safe script:

```
.\DuplicateTool.ps1
```

### Delete Duplicates and Leave Breadcrumbs (Main Script Only)

To delete duplicate files and leave breadcrumbs (with confirmation prompt), use:

```
.\DuplicateTool-Delete.ps1 -Delete
```

- The script will prompt you to confirm before deleting any files.
- If you confirm, it will delete duplicates and leave breadcrumb files.
- If you do not confirm, it will only generate the report.

**Warning:** When using `DuplicateTool-Delete.ps1 -Delete` and confirming, duplicate files will be permanently deleted and breadcrumb files will be created in their place. Make sure you have backups or are certain before confirming the prompt.

### Safe Mode

If you want to ensure **no files are ever deleted**, use `DuplicateTool.ps1`. This script has all deletion and breadcrumb logic removed and is safe for reporting only.

## Output Format

The output CSV file contains the following columns:

- **File Name**: Name of the duplicate file
- **Duplicate Count**: Number of duplicates for this file
- **Parent Path**: Directory path where the file is located
- **Duplicate Key**: Aparavi's internal duplicate key that identifies identical content

When duplicate files are removed, a breadcrumb text file is created in their place with:
- Path to the original file
- Name and path of the removed duplicate
- The duplicate key (hash) that identified them as duplicates
- Timestamp of when the file was removed

Additionally, all deletions are logged to a timestamped log file (`DuplicateFiles_Deletions_[timestamp].log`) with detailed information about:
- When the deletion occurred
- Which file was deleted
- Path to the original file that was kept
- Where the breadcrumb file was created

### Example Output

```csv
File Name,Duplicate Count,Parent Path,Duplicate Key
user_manual.pdf,3,/MC-Legion Aggregator-Collector/File System/C:/Aparavi/Data/Demo/Department1/,f1a47cb83e4d6c46a32f70c4b5f684e9
user_manual.pdf,3,/MC-Legion Aggregator-Collector/File System/C:/Aparavi/Data/Demo/Department2/,f1a47cb83e4d6c46a32f70c4b5f684e9
user_manual.pdf,3,/MC-Legion Aggregator-Collector/File System/C:/Aparavi/Data/Demo/Department3/,f1a47cb83e4d6c46a32f70c4b5f684e9
sample_data.xlsx,2,/MC-Legion Aggregator-Collector/File System/C:/Aparavi/Data/Demo/Finance/,7d9c8b3a1f5e2d0c6b4a7e9d8c1b3a5f
sample_data.xlsx,2,/MC-Legion Aggregator-Collector/File System/C:/Aparavi/Data/Demo/Reports/,7d9c8b3a1f5e2d0c6b4a7e9d8c1b3a5f
logo.png,5,/MC-Legion Aggregator-Collector/File System/C:/Aparavi/Data/Demo/Marketing/Templates/,3e8f7d6c5b4a3e2d1c0b9a8f7e6d5c4b
logo.png,5,/MC-Legion Aggregator-Collector/File System/C:/Aparavi/Data/Demo/Marketing/Website/,3e8f7d6c5b4a3e2d1c0b9a8f7e6d5c4b
logo.png,5,/MC-Legion Aggregator-Collector/File System/C:/Aparavi/Data/Demo/Branding/Current/,3e8f7d6c5b4a3e2d1c0b9a8f7e6d5c4b
logo.png,5,/MC-Legion Aggregator-Collector/File System/C:/Aparavi/Data/Demo/Branding/Archive/,3e8f7d6c5b4a3e2d1c0b9a8f7e6d5c4b
logo.png,5,/MC-Legion Aggregator-Collector/File System/C:/Aparavi/Data/Demo/Assets/,3e8f7d6c5b4a3e2d1c0b9a8f7e6d5c4b
```

The above example shows:

- Three copies of `user_manual.pdf` found in different department folders
- Two copies of `sample_data.xlsx` found in Finance and Reports folders
- Five copies of `logo.png` found in various marketing and branding folders

Each group of files with the same duplicate key (hash) represents files with identical content.

## Notes

- The CSV output files are added to `.gitignore` to prevent them from being tracked in version control
- Each run creates a uniquely timestamped output file (e.g., `DuplicateFiles_Report_20250519-183446.csv`) to prevent overwriting previous reports
- Duplicate filtering ensures each unique file content hash (dupKey) is processed only once
- The duplicate cleanup feature is disabled by default and requires manual activation
- Files in the main search directory are considered "originals" and won't be deleted
- All deletions are logged to a timestamped log file for auditing and tracking
- Always make backups before enabling the cleanup feature to delete duplicate files
- You can adjust the `$LimitResults` parameter to control how many duplicate groups are processed
- The script includes progress indicators and error handling for each duplicate key group