# Eyetracker Data Preprocessing

This directory contains MATLAB scripts for converting eyetracker data from `.mat` format to `.csv` format for statistical analysis in R.

## Scripts Overview

### `eyetracker_mat_to_csv_converter.m`
Main conversion function that processes individual task-specific MATLAB files.

**Features:**
- Automatically detects task type (ADT, VDT, CDT, MST) from filename
- Extracts subject ID from filename
- Applies task-specific data transformations
- Exports to CSV format with proper column structure

**Usage:**
```matlab
% Convert a single file
eyetracker_mat_to_csv_converter('subject74_Aoddball_session1_run1.mat', './output/')

% Save to same directory as input
eyetracker_mat_to_csv_converter('subject74_Voddball_session1_run1.mat')
```

### `batch_convert_eyetracker_files.m`
Batch processing script for converting multiple files.

**Features:**
- Processes all task-specific `.mat` files in a directory
- Generates conversion summary statistics
- Handles errors gracefully
- Saves detailed summary report

**Usage:**
```matlab
% Convert all files in a directory
batch_convert_eyetracker_files('./ParticipantsOutput/', './csv_output/')

% Use default output directory (input_dir/csv_output/)
batch_convert_eyetracker_files('./ParticipantsOutput/')
```

## Supported Tasks

### ADT (Auditory Discrimination Task)
- **Input files:** `subject*_Aoddball_*.mat`
- **Output:** `ADT_S{id}.csv`
- **Columns:**
  1. Subject ID
  2. Accuracy (iscorr)
  3. Response (ActualResponse)
  4. Stimulus Level (Oddball_level)
  5. Grip Level (grip_level)
  6. Response Duration
  7. Confidence Rating
  8. Is Oddball (isoddball)

### VDT (Visual Discrimination Task)
- **Input files:** `subject*_Voddball_*.mat`
- **Output:** `VDT_S{id}.csv`
- **Columns:** Same as ADT

### CDT (Change Detection Task)
- **Input files:** `subject*_CD_*.mat`
- **Output:** `CDT_S{id}.csv`
- **Columns:**
  1. Subject ID
  2. Accuracy (iscorr)
  3. Response (ActualResponse)
  4. Orientation Change (degrees: -90, -45, -20, -6, 0, 6, 20, 45, 90)
  5. Grip Level (0.05 or 0.4)
  6. Response Duration
  7. Confidence Rating

### MST (Mnemonic Similarity Task)
- **Input files:** `subject*_MST_*.mat`
- **Output:** Two files:
  - `MST_S{id}.csv` (Encoding phase)
  - `MST_test_S{id}.csv` (Test phase)

**Encoding phase columns:**
  1. Subject ID
  2. Response (ActualResponse)
  3. Indoor/Outdoor (indoor)
  4. Grip Level (grip_level)
  5. Response Duration
  6. Image Set
  7. Image Number

**Test phase columns:**
  1. Subject ID
  2. Response (ActualResponse_test)
  3. Image Type (Target/Lure/Foil)
  4. Image Number
  5. Accuracy (test_iscorr)
  6. Response Duration
  7. Confidence Response
  8. Confidence Report Duration

## Data Transformations

### CDT Orientation Coding
The script applies the following transformations:
```matlab
% Orientation direction: 1 → -1, 2 → +1
% Degrees: 1→0, 2→6, 3→20, 4→45, 5→90
% Final degrees = orientation × degrees (signed change)
```

### Grip Level Recoding
```matlab
% ADT/VDT: Uses gf_trPer values directly
% CDT/MST: 1 → 0.4, 2 → 0.05
```

## Requirements

- MATLAB R2019b or later
- No additional toolboxes required

## Example Workflow

### Converting All Files
```matlab
% Set up paths
input_dir = './ParticipantsOutput/';
output_dir = './csv_output/';

% Run batch conversion
batch_convert_eyetracker_files(input_dir, output_dir);

% Check the summary report
type('./csv_output/conversion_summary.txt');
```

### Converting Specific Files
```matlab
% Convert individual task files for subject 74
eyetracker_mat_to_csv_converter('subject74_Aoddball_session1_run1.mat', './csv/');
eyetracker_mat_to_csv_converter('subject74_Voddball_session1_run1.mat', './csv/');
eyetracker_mat_to_csv_converter('subject74_CD_session1_run1.mat', './csv/');
eyetracker_mat_to_csv_converter('subject74_MST_session1_run1.mat', './csv/');
```

## Output

### CSV Files
- One CSV file per task per subject
- No headers (column names not included)
- Numeric data only
- Ready for import into R

### Summary Report
The batch conversion generates `conversion_summary.txt` containing:
- Conversion date and time
- Total files processed
- Success/failure counts
- Task type breakdown
- Processing time statistics
- List of any failed conversions

## Error Handling

The scripts include robust error handling:
- Invalid filename format → Clear error message
- Missing required variables → Graceful failure with details
- Batch processing continues even if individual files fail
- Failed conversions are logged in summary report

## Notes

### Filename Requirements
Input filenames must follow the pattern:
- `subject{ID}_{TASK}_session{N}_run{N}_{date}.mat`
- Task identifiers: `Aoddball`, `Voddball`, `CD`, `MST`

### MATLAB Workspace
The conversion functions do not pollute the MATLAB workspace. The original scripts included `clear` commands, but these have been replaced with proper function scoping.

### Data Integrity
All transformations preserve the original data relationships and apply consistent recoding rules across subjects.

## Citation

If you use these scripts, please cite:
> LC-YA Study Team (2024). Eyetracker Data Preprocessing Scripts. 
> GitHub: https://github.com/mohdasti/LCYA

## Contact

For questions or issues, please open an issue on the GitHub repository.

