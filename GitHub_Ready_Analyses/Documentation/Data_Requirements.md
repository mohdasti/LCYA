# Data Requirements

## Overview
This document specifies the data requirements for running the LC-YA pupillometry analysis pipeline.

## Required Data Files

### 1. Pupil AUC Data
**File**: `PI_Feedback_Outputs/Combined_Dual_AUC_Data.csv`

**Structure**:
```csv
sub,task,condition,mean_physical_auc,se_physical_auc,mean_cognitive_auc,se_cognitive_auc
1,CDT,Hard / High,1234.56,45.67,234.56,12.34
1,CDT,Hard / Low,987.65,43.21,198.76,11.23
...
```

**Required Columns**:
- `sub`: Subject ID (numeric)
- `task`: Task name (CDT, ADT, VDT)
- `condition`: Condition string (e.g., "Hard / High", "Easy / Low")
- `mean_physical_auc`: Total AUC measure
- `se_physical_auc`: Standard error of Total AUC
- `mean_cognitive_auc`: Cognitive AUC measure
- `se_cognitive_auc`: Standard error of Cognitive AUC

### 2. Behavioral Data
**File**: `Complete_Manuscript_Results/complete_analysis_data.csv`

**Structure**:
```csv
sub,task,difficulty,effort,accuracy,rt_ms,rt_scaled
S1,CDT,Hard,High,0.85,1250.5,6.23
S1,CDT,Hard,Low,0.92,1180.2,6.07
...
```

**Required Columns**:
- `sub`: Subject ID (string with "S" prefix)
- `task`: Task name (CDT, ADT, VDT)
- `difficulty`: Difficulty level (Easy, Hard)
- `effort`: Effort level (Low, High)
- `accuracy`: Proportion correct (0-1)
- `rt_ms`: Reaction time in milliseconds
- `rt_scaled`: Log-transformed reaction time

### 3. Raw Pupil Data (Optional)
**Directory**: `100 Hz/`

**Purpose**: Used for pupil waveform analysis and baseline correction

**File Format**: CSV files with time-series pupil data
- Time columns: `time_from_squeeze`, `time_from_stimulus`
- Pupil data: `pupil_diameter` or similar
- Trial information: `sub`, `task`, `condition`, `trial_index`

## Data Quality Requirements

### Completeness
- **Missing Data**: <5% missing values per condition
- **Complete Cases**: At least 30 subjects with complete data across all conditions
- **Trial Count**: Minimum 20 trials per condition per subject

### Data Integrity
- **Subject IDs**: Consistent across all data files
- **Condition Labels**: Standardized format (e.g., "Hard / High")
- **Value Ranges**: 
  - Accuracy: 0-1
  - Reaction times: 200-5000ms
  - AUC values: Positive numbers

### Validation Checks
```r
# Data validation function
validate_data <- function(auc_data, behavior_data) {
  # Check required columns
  required_auc <- c("sub", "task", "condition", "mean_physical_auc", "mean_cognitive_auc")
  required_behav <- c("sub", "task", "difficulty", "effort", "accuracy", "rt_ms")
  
  # Check column existence
  stopifnot(all(required_auc %in% names(auc_data)))
  stopifnot(all(required_behav %in% names(behavior_data)))
  
  # Check data ranges
  stopifnot(all(behavior_data$accuracy >= 0 & behavior_data$accuracy <= 1))
  stopifnot(all(behavior_data$rt_ms > 0))
  stopifnot(all(auc_data$mean_physical_auc > 0))
  stopifnot(all(auc_data$mean_cognitive_auc > 0))
  
  # Check subject overlap
  auc_subs <- unique(auc_data$sub)
  behav_subs <- unique(as.numeric(gsub("S", "", behavior_data$sub)))
  overlap <- length(intersect(auc_subs, behav_subs))
  
  cat("Data validation complete:\n")
  cat("- AUC subjects:", length(auc_subs), "\n")
  cat("- Behavioral subjects:", length(behav_subs), "\n")
  cat("- Overlapping subjects:", overlap, "\n")
  
  return(overlap >= 30)  # Minimum 30 subjects
}
```

## Data Preprocessing

### Standard Preprocessing Steps
1. **Subject ID Harmonization**: Convert "S1" to 1 format
2. **Condition Parsing**: Extract difficulty and effort from condition strings
3. **Data Merging**: Join AUC and behavioral data by subject, task, difficulty, effort
4. **Missing Data Handling**: Listwise deletion for incomplete cases
5. **Outlier Detection**: Visual inspection and statistical tests

### Example Preprocessing Code
```r
# Load and preprocess data
load_and_preprocess <- function() {
  # Load data
  auc_data <- read_csv("PI_Feedback_Outputs/Combined_Dual_AUC_Data.csv")
  behav_data <- read_csv("Complete_Manuscript_Results/complete_analysis_data.csv")
  
  # Preprocess AUC data
  auc_processed <- auc_data %>%
    mutate(
      sub = as.numeric(sub),
      difficulty = str_extract(condition, "^[^/]+") %>% str_trim(),
      effort = str_extract(condition, "[^/]+$") %>% str_trim(),
      task = factor(task, levels = c("CDT", "ADT", "VDT")),
      mean_total_auc = mean_physical_auc,
      mean_cognitive_auc = mean_cognitive_auc
    )
  
  # Preprocess behavioral data
  behav_processed <- behav_data %>%
    filter(!is.na(accuracy)) %>%
    group_by(sub, task, difficulty, effort) %>%
    summarise(mean_accuracy = mean(accuracy, na.rm = TRUE), .groups = 'drop') %>%
    mutate(
      sub = as.numeric(str_remove(sub, "S")),
      difficulty = factor(difficulty, levels = c("Easy", "Hard")),
      effort = factor(effort, levels = c("Low", "High")),
      task = factor(task, levels = c("CDT", "ADT", "VDT"))
    )
  
  # Merge data
  merged_data <- auc_processed %>%
    left_join(behav_processed, by = c("sub", "task", "difficulty", "effort"))
  
  # Validate
  if (!validate_data(auc_processed, behav_processed)) {
    stop("Data validation failed")
  }
  
  return(merged_data)
}
```

## Data Storage Recommendations

### File Organization
```
LC–YA/
├── Data/
│   ├── Raw/
│   │   ├── Pupil/
│   │   │   └── 100 Hz/
│   │   └── Behavioral/
│   ├── Processed/
│   │   ├── PI_Feedback_Outputs/
│   │   └── Complete_Manuscript_Results/
│   └── Derived/
│       └── Analysis_Ready/
├── Analyses/
│   └── GitHub_Ready_Analyses/
└── Results/
    ├── Figures/
    ├── Tables/
    └── Reports/
```

### Data Versioning
- **Raw Data**: Immutable, version-controlled
- **Processed Data**: Versioned with timestamps
- **Derived Data**: Generated on-demand from processed data

### Backup Strategy
- **Local**: Regular backups to external storage
- **Cloud**: Encrypted cloud storage for sensitive data
- **Version Control**: Git LFS for large data files

## Privacy and Ethics

### Data Anonymization
- **Subject IDs**: Use numeric codes, not personal identifiers
- **Demographics**: Remove or aggregate sensitive information
- **Location Data**: Remove or generalize geographic information

### Data Sharing
- **Public Repositories**: Only share anonymized, aggregated data
- **Collaboration**: Use secure data sharing platforms
- **Consent**: Ensure participants consented to data sharing

### Compliance
- **GDPR**: For European participants
- **HIPAA**: For US medical data
- **Institutional**: Follow university/IRB guidelines

## Troubleshooting

### Common Data Issues

#### 1. Missing Files
```r
# Check file existence
required_files <- c(
  "PI_Feedback_Outputs/Combined_Dual_AUC_Data.csv",
  "Complete_Manuscript_Results/complete_analysis_data.csv"
)

for (file in required_files) {
  if (!file.exists(file)) {
    stop("Missing required file: ", file)
  }
}
```

#### 2. Column Name Mismatches
```r
# Check column names
check_columns <- function(data, expected_cols) {
  missing <- setdiff(expected_cols, names(data))
  if (length(missing) > 0) {
    stop("Missing columns: ", paste(missing, collapse = ", "))
  }
}
```

#### 3. Data Type Issues
```r
# Check data types
check_types <- function(data) {
  # Numeric columns should be numeric
  numeric_cols <- c("mean_physical_auc", "mean_cognitive_auc", "accuracy")
  for (col in numeric_cols) {
    if (col %in% names(data) && !is.numeric(data[[col]])) {
      warning("Column ", col, " should be numeric")
    }
  }
}
```

#### 4. Subject ID Inconsistencies
```r
# Check subject ID consistency
check_subject_ids <- function(auc_data, behav_data) {
  auc_subs <- unique(auc_data$sub)
  behav_subs <- unique(as.numeric(gsub("S", "", behav_data$sub)))
  
  only_auc <- setdiff(auc_subs, behav_subs)
  only_behav <- setdiff(behav_subs, auc_subs)
  
  if (length(only_auc) > 0) {
    warning("Subjects only in AUC data: ", paste(only_auc, collapse = ", "))
  }
  
  if (length(only_behav) > 0) {
    warning("Subjects only in behavioral data: ", paste(only_behav, collapse = ", "))
  }
}
```

## Data Dictionary

### AUC Data Variables
| Variable | Type | Description | Range |
|----------|------|-------------|-------|
| `sub` | Numeric | Subject ID | 1-N |
| `task` | Factor | Task name | CDT, ADT, VDT |
| `condition` | Character | Condition string | "Easy/Low", "Hard/High", etc. |
| `mean_physical_auc` | Numeric | Total AUC measure | >0 |
| `se_physical_auc` | Numeric | Standard error of Total AUC | >0 |
| `mean_cognitive_auc` | Numeric | Cognitive AUC measure | >0 |
| `se_cognitive_auc` | Numeric | Standard error of Cognitive AUC | >0 |

### Behavioral Data Variables
| Variable | Type | Description | Range |
|----------|------|-------------|-------|
| `sub` | Character | Subject ID with "S" prefix | S1-SN |
| `task` | Factor | Task name | CDT, ADT, VDT |
| `difficulty` | Factor | Difficulty level | Easy, Hard |
| `effort` | Factor | Effort level | Low, High |
| `accuracy` | Numeric | Proportion correct | 0-1 |
| `rt_ms` | Numeric | Reaction time (ms) | 200-5000 |
| `rt_scaled` | Numeric | Log-transformed RT | 5-8 |

### Derived Variables
| Variable | Type | Description | Source |
|----------|------|-------------|--------|
| `mean_total_auc` | Numeric | Alias for mean_physical_auc | AUC data |
| `difficulty_parsed` | Factor | Parsed from condition | AUC data |
| `effort_parsed` | Factor | Parsed from condition | AUC data |
| `sub_numeric` | Numeric | Numeric subject ID | Behavioral data |













