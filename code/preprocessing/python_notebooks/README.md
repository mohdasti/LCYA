# Python Data Processing Notebooks

These Jupyter notebooks (designed for Google Colab) were used to process raw behavioral data from MATLAB `.mat` files and integrate grip force measurements for the LC-YA study.

**Authors**: Mohammad Dastgheib & Andrew Sun

## Notebooks Overview

### 1. AVDT LC-YA_aggregate_trial_level_data.ipynb
**Purpose**: Process Auditory and Visual Discrimination Task (ADT/VDT) data

**Key Functions**:
- Aggregates trial-level data from MATLAB `.mat` files
- Integrates grip force measurements from CSV files
- Calculates grip force AUC (Area Under Curve) metrics
- Adds Signal Detection Theory (SDT) tags (hit, miss, false alarm, correct rejection)
- Performs data validation and quality checks

**Outputs**:
- `lcya_behdata_trial_avdt.csv`: Trial-level data for ADT and VDT tasks

### 2. CDT_LC-YA_aggregate_trial_level_data.ipynb
**Purpose**: Process Change Detection Task (CDT) data

**Key Functions**:
- Aggregates trial-level CDT data from MATLAB files
- Integrates grip force measurements
- **Note**: Corrects flipped `iscorr` coding from original MATLAB task code
- Calculates orientation change differences (signed: -90 to +90 degrees)
- Adds SDT confusion matrix tags
- Performs data validation checks

**Outputs**:
- `lcya_behdata_trial_cdt.csv`: Trial-level data for CDT task

### 3. MST_LC-YA_aggregate_trial_level_data.ipynb
**Purpose**: Process Mnemonic Similarity Task (MST) data

**Key Functions**:
- Processes MST encoding phase (study) data
- Processes MST test phase data
- Merges grip force measures from encoding phase to test phase
- Adds lure bin classifications (similarity levels)
- Calculates confidence rating metrics
- Performs data validation

**Outputs**:
- `lcya_behdata_trial_mst.csv`: Trial-level data for MST task (combined study and test phases)

### 4. LC YA aggregate groupby data.ipynb
**Purpose**: Aggregate trial-level data and perform SDT calculations

**Key Functions**:
- Groups data by subject, task, stimulus level, and grip condition
- Calculates Signal Detection Theory (SDT) measures:
  - d' (d-prime): sensitivity
  - beta: response bias
  - c: criterion
  - Ad: area under ROC curve
- Calculates psychometric curve slopes
- Prepares data for hierarchical meta-d' analysis (HMeta-d MATLAB package)
- Applies various data filters (missed responses, invalid grip, etc.)

**Outputs**:
- `lcya_sub_task_stimlev_grip_sdt.csv`: Aggregated data with SDT measures
- `lcya_sub_task_stimlev_sdt.csv`: Aggregated data (no grip grouping)
- Multiple `nR_s` CSV files for HMeta-d analysis

## Data Processing Pipeline

### Step 1: MATLAB → CSV Conversion
The MATLAB scripts (in `../`) convert raw `.mat` files to CSV format.

### Step 2: Trial-Level Aggregation
These notebooks aggregate individual trial data and integrate:
- Behavioral responses (accuracy, reaction time, confidence)
- Grip force measurements (AUC metrics)
- Task-specific manipulations

### Step 3: Quality Control
Each notebook includes validation checks:
- Grip force compliance (correct force levels and duration)
- Performance patterns (accuracy increases with stimulus difficulty)
- Data completeness

### Step 4: Data Aggregation
The groupby notebook aggregates data and calculates:
- SDT measures per subject/task/condition
- Psychometric curve slopes
- Metacognitive measures

## Key Variables

### Grip Force Metrics
- **`auc`**: Raw area under grip force curve
- **`auc_rel_mvc`**: AUC relative to Maximum Voluntary Contraction
- **`auc_prop_targ`**: AUC relative to target force level
- **`prop_valid_grip_samples`**: Proportion of valid grip samples

### Behavioral Measures
- **`iscorr`**: Trial accuracy (0/1)
- **`resp1`**: Primary response
- **`resp1RT`**: Reaction time for primary response
- **`resp2`**: Confidence rating (1-4)
- **`resp2RT`**: Reaction time for confidence rating

### SDT Measures
- **`py_d`**: d-prime (sensitivity)
- **`py_beta`**: Response bias
- **`py_c`**: Criterion
- **`py_Ad`**: Area under ROC curve
- **`hit_rate`, `fa_rate`, etc.**: SDT outcome rates

## Running the Notebooks

### Requirements
- Google Colab (or Jupyter with required packages)
- Python packages: `scipy`, `pandas`, `numpy`, `matplotlib`
- Access to Google Drive with LC-YA data

### Execution Order
1. Run MATLAB conversion scripts first (see `../`)
2. Run task-specific notebooks (AVDT, CDT, MST)
3. Run aggregate groupby notebook for SDT calculations

### Important Notes
- Notebooks are designed for Google Colab
- Data paths point to Google Drive shared folders
- **CDT-specific**: The notebook corrects flipped `iscorr` coding from original task
- **MST-specific**: Merges grip data from study phase to test phase

## Data Validation

Each notebook includes sanity checks:
- ✅ Grip force compliance validation
- ✅ Performance vs. stimulus difficulty verification
- ✅ Response distribution checks
- ✅ Data completeness verification

## Authors

- **Mohammad Dastgheib**: Primary developer
- **Andrew Sun**: Co-developer

## Integration with R Analysis

These notebooks create the CSV files that feed into the R analysis scripts in `analysis/manuscript_scripts/`:
- `lcya_behdata_trial_avdt.csv` → Used by `LCYA_Final_Corrected_Analysis.R`
- `lcya_behdata_trial_cdt.csv` → Used by `LCYA_Final_Corrected_Analysis.R`
- `lcya_behdata_trial_mst.csv` → Used for MST-specific analyses

## Citation

If you use these scripts, please cite:
> Dastgheib, M. & Sun, A. (2024). LC-YA Data Processing Pipeline. 
> GitHub: https://github.com/mohdasti/LCYA

