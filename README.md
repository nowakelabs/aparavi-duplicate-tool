# Aparavi Duplicate File Tool

A PowerShell tool for identifying and reporting duplicate files in Aparavi data management systems. This utility leverages Aparavi's API to find files with identical content (same dupKey) and generate CSV reports for analysis.

## Requirements

- PowerShell 5.1 or higher
- Aparavi system with API access
- Basic authentication credentials for the Aparavi API

## Configuration

The script uses the following configuration parameters at the top of the `dupkeys.ps1` file:

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
```

Update these values to match your Aparavi environment before running the script.

## How It Works

The script operates in two main steps:

1. **Find Duplicate Keys**: Queries Aparavi's API to find all unique `dupKey` values for files in the specified directory that have duplicates (dupKey > 1).

2. **Get File Details**: For each unique duplicate key found, it queries the API again to retrieve detailed information about all files sharing that key.

3. **Export Report**: Exports a timestamped CSV report containing file names, duplicate counts, parent paths, and duplicate keys for all identified duplicate files.

## Key Features

- **Timestamped Reports**: Each run creates a uniquely timestamped report to prevent overwriting previous results
- **Duplicate Filtering**: The script ensures each duplicate key is processed only once, eliminating redundant API calls
- **Progress Tracking**: Shows completion percentage and details about each group of duplicates as they're processed
- **Error Handling**: Includes robust error handling for API request failures

## Usage

1. Configure the script parameters as needed
2. Run the script in PowerShell:

```
.\dupkeys.ps1
```

3. The script will generate a CSV report with the duplicate files information

## Output Format

The output CSV file contains the following columns:

- **File Name**: Name of the duplicate file
- **Duplicate Count**: Number of duplicates for this file
- **Parent Path**: Directory path where the file is located
- **Duplicate Key**: Aparavi's internal duplicate key that identifies identical content

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
- You can adjust the `$LimitResults` parameter to control how many duplicate groups are processed
- The script includes progress indicators and error handling for each duplicate key group