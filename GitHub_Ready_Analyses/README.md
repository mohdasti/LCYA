# LC-YA Pupillometry Analysis Pipeline

This repository contains the complete analysis pipeline for the LC-YA (Leveraging Cognitive Youth-Adult) pupillometry study examining the effects of task difficulty and physical effort on pupillary responses and behavioral performance.

## Study Overview

**Research Question**: How do task difficulty and physical effort manipulations affect pupillary responses and behavioral performance across different cognitive tasks?

**Design**: 2×2 factorial design (Easy/Hard difficulty × Low/High physical effort) across three cognitive tasks:
- **CDT**: Change Detection Task
- **ADT**: Auditory Discrimination Task  
- **VDT**: Visual Discrimination Task

**Sample**: N=39 participants with repeated measures across conditions

## Repository Structure

```
GitHub_Ready_Analyses/
├── 01_Pupil_Waveforms/          # Figure 3: Pupil waveform analysis
├── 02_AUC_Analyses/             # Figure 4: AUC bar plots
├── 03_Individual_Differences/   # Individual differences analyses
├── 04_Behavioral_Plots/         # Figure 2: Behavioral performance plots
├── 05_Manuscript_Figures/       # Final figures and results
│   ├── Manuscript_Figures_Only/ # Publication-ready figures
│   └── results/                 # Statistical results and reports
├── Documentation/               # Detailed documentation
└── README.md                    # This file
```

## Quick Start

To reproduce all manuscript figures:

1. **Set up R environment** (see Dependencies section)
2. **Ensure data files are available** (see Data Requirements section)
3. **Run scripts in order**:
   ```r
   # From GitHub_Ready_Analyses directory
   source("01_Pupil_Waveforms/LCYA_Isolated_Cognitive_AUC_Analysis.R")
   source("02_AUC_Analyses/LCYA_Updated_Combined_AUC_Plots.R")
   source("04_Behavioral_Plots/Figure2_Clean_Final_Version.R")
   ```
4. **Find outputs** in `05_Manuscript_Figures/Manuscript_Figures_Only/`

## Analysis Pipeline Structure

### 01_Pupil_Waveforms/
**Main Script**: `LCYA_Isolated_Cognitive_AUC_Analysis.R`

**Purpose**: Generate publication-ready pupil waveform plots (Figure 3) showing the effects of task difficulty and physical effort over time.

**Key Features**:
- Baseline correction using 500ms pre-squeeze window (-0.5s to 0s)
- Time-locked to squeeze onset with range from -0.5s to response onset
- Smoothed GAM trajectories with 95% confidence intervals
- Publication-ready formatting with proper labels and legends
- Task-specific event markers (e.g., "Array onset" for CDT, "Target onset" for ADT/VDT)
- Baseline and AUC period annotations with horizontal bars:
  - **CDT**: Pre-trial Baseline (grey) and Total AUC (blue) only
  - **ADT/VDT**: Pre-trial Baseline (grey), Total AUC (blue), Pre-stimulus Baseline (grey), and Cognitive AUC (orange)

**Outputs**:
- `Figure3_Pupil_Waveforms.png` (saved to `05_Manuscript_Figures/Manuscript_Figures_Only/`)
- `Cognitive_Pupil_Waveforms_Publication_Ready_v2.png` (saved to `PI_Feedback_Outputs/`)
- Linear mixed-effects model results for Total AUC and Cognitive AUC

### 02_AUC_Analyses/
**Main Script**: `LCYA_Updated_Combined_AUC_Plots.R`

**Purpose**: Generate bar plots (Figure 4) showing effects of task difficulty and physical effort on pupillary response measures.

**Key Features**:
- Separate plots for Total AUC and Cognitive AUC
- Implements analytical recommendations (CDT cognitive AUC excluded)
- Publication-ready formatting with proper error bars and legends
- Task-specific statistical models (CDT: effort only; ADT/VDT: full 2×2 ANOVA)

**Scripts**:
- `LCYA_Updated_Combined_AUC_Plots.R` - Main script generating separate Total AUC and Cognitive AUC plots
- `LCYA_Figure4_Merged_AUC_Plot.R` - Optional script for merged visualization (not used in manuscript)

**Outputs**:
- `Figure4_Total_AUC.png` - Total AUC effects across all tasks
- `Figure4_Cognitive_AUC.png` - Cognitive AUC effects (ADT and VDT only)

### 03_Individual_Differences/
**Main Scripts**: 
- `Bivariate_Individual_Differences_brms.R` (Primary analysis)
- `Corrected_Individual_Differences_rmcorr.R` (Sensitivity analysis)
- `Add_Cognitive_AUC_Subject_Means.R` (Supplementary analysis)

**Purpose**: Examine individual-level associations between physiological and behavioral effort sensitivity.

**Key Features**:
- **Primary**: Multivariate Bayesian mixed-effects models using brms
- **Sensitivity**: Repeated measures correlation (rmcorr) and subject-means approaches
- **Target estimand**: Correlation between subject-specific effort slopes across physiological and behavioral outcomes
- **Construct alignment**: Total AUC ↔ physical effort; Cognitive AUC ↔ cognitive effort

**Outputs**:
- `results/primary_individual_differences_slope_correlations.csv`
- `results/Individual_Differences_Brms_Report.md`
- `results/rmcorr_log.txt`

### 04_Behavioral_Plots/
**Main Script**: `Figure2_Clean_Final_Version.R`

**Purpose**: Generate behavioral performance plots (Figure 2) showing accuracy and reaction time effects across tasks and conditions.

**Key Features**:
- Clean, publication-ready formatting
- Proper axis labels and legends
- Separate panels for accuracy (top row) and reaction time (bottom row)
- Consistent color scheme across all figures

**Outputs**:
- `Figure2_Task_Performance_Effects.png` (saved to `05_Manuscript_Figures/Manuscript_Figures_Only/`)

### 05_Manuscript_Figures/
**Contents**: All generated figures and results files

**Subdirectories**:
- `Manuscript_Figures_Only/` - Final publication-ready figures (Figures 2, 3, and 4)
- `results/` - Statistical analysis results and reports
  - `Individual_Differences_Brms_Report.md` - Complete Bayesian analysis report
  - `primary_individual_differences_slope_correlations.csv` - Individual differences correlations
  - Model diagnostics and convergence reports

**Key Figures**:
- `Manuscript_Figures_Only/Figure2_Task_Performance_Effects.png` - Behavioral performance
- `Manuscript_Figures_Only/Figure3_Pupil_Waveforms.png` - Pupil waveforms
- `Manuscript_Figures_Only/Figure4_Total_AUC.png` - Total AUC bar plots
- `Manuscript_Figures_Only/Figure4_Cognitive_AUC.png` - Cognitive AUC bar plots

## Key Methodological Decisions

### Pupil Waveform Analysis (Figure 3)
- **Baseline period**: 500ms pre-squeeze (-0.5s to 0s) for optimal separation
- **Time range**: From -0.5s (baseline period) to response onset for complete trial visualization
- **Smoothing**: GAM trajectories with 95% confidence intervals
- **Baseline correction**: Global baseline (B0) applied throughout to ensure convergence at squeeze onset
- **CDT-specific**: Excludes Cognitive AUC analysis and Pre-stimulus Baseline (per analytical recommendations)
- **ADT/VDT-specific**: Includes Pre-stimulus Baseline (B2b) showing 500ms window before target/stimulus onset

### AUC Measures
- **Pre-trial Baseline (B0)**: 500ms window (-0.5s to 0s) before squeeze onset, used for global baseline correction
- **Pre-stimulus Baseline (B2b)**: 500ms window before target/stimulus onset, used specifically for Cognitive AUC calculation
- **Total AUC**: Raw pupil data from squeeze onset (0s) to response onset
- **Cognitive AUC**: Isolated pupil data (B0-corrected) from 300ms after target/stimulus onset to response onset
- **Task-specific analyses**: 
  - **CDT**: Physical effort only (Total AUC); Cognitive AUC excluded per analytical recommendations
  - **ADT/VDT**: Full 2×2 ANOVA (difficulty × effort) for both Total AUC and Cognitive AUC

### Individual Differences Analysis
- **Primary method**: Multivariate Bayesian mixed-effects models (brms)
- **Target estimand**: Correlation between subject-specific effort slopes
- **Sensitivity analyses**: rmcorr and subject-means correlations
- **Statistical approach**: Bayesian inference with credible intervals, avoiding p-value corrections

## Dependencies

### Required R Packages
```r
# Core analysis
library(tidyverse)      # Data manipulation and visualization
library(brms)          # Bayesian mixed-effects models
library(rmcorr)        # Repeated measures correlation
library(posterior)     # Bayesian posterior analysis

# Visualization
library(ggplot2)       # Plotting
library(patchwork)     # Combining plots
library(mgcv)          # GAM smoothing

# Mixed-effects models
library(lme4)          # Linear mixed-effects models
library(lmerTest)      # p-values for mixed-effects models
```

### Data Requirements

**Note**: Due to data privacy and file size constraints, raw data files are not included in this repository. Users need to provide their own data files with the following structure:

- `100 Hz/` directory - Raw pupil data files (downsampled to 100 Hz)
  - Expected format: `*_DS100_merged.csv` files with columns for `sub`, `trial_index`, `time`, `pupil`, `duration_label`, `stimLev`, `isStrength`
  
- `PI_Feedback_Outputs/Combined_Dual_AUC_Data.csv` - Processed pupil AUC measures (generated by analysis scripts)

- `Complete_Manuscript_Results/complete_analysis_data.csv` - Behavioral data (accuracy and reaction time)

**Directory Structure**: Scripts use absolute paths (e.g., `/Users/mohdasti/Documents/LC–YA`) that need to be adjusted for your local setup. Update the `BASE_DIR` variable at the top of each script to point to your data directory.

**Example path modification**:
```r
# In each script, change:
BASE_DIR <- "/Users/mohdasti/Documents/LC–YA"
# To your local path:
BASE_DIR <- "/path/to/your/LC–YA"
```

## Usage Instructions

### 1. Pupil Waveform Analysis
```r
# Run main pupil waveform analysis
source("01_Pupil_Waveforms/LCYA_Isolated_Cognitive_AUC_Analysis.R")
```

### 2. AUC Bar Plots
```r
# Generate AUC bar plots
source("02_AUC_Analyses/LCYA_Updated_Combined_AUC_Plots.R")
```

### 3. Individual Differences Analysis
```r
# Primary analysis (Bayesian)
source("03_Individual_Differences/Bivariate_Individual_Differences_brms.R")

# Sensitivity analysis (rmcorr)
source("03_Individual_Differences/Corrected_Individual_Differences_rmcorr.R")

# Supplementary analysis
source("03_Individual_Differences/Add_Cognitive_AUC_Subject_Means.R")
```

### 4. Behavioral Plots
```r
# Generate behavioral performance plots
source("04_Behavioral_Plots/Figure2_Clean_Final_Version.R")
```

## Key Results Summary

### Pupil Waveform Effects
- **Physical effort**: Consistent increases in pupillary response across all tasks
- **Task difficulty**: Minimal effects on pupil waveforms
- **Baseline correction**: 500ms window provides optimal separation

### AUC Effects
- **Total AUC**: Significant physical effort effects across all tasks
- **Cognitive AUC**: Task-specific patterns with ADT/VDT showing cognitive effort effects
- **CDT**: Physical effort only (per analytical recommendations)

### Individual Differences
- **Primary finding**: No compelling evidence for individual-level associations between physiological and behavioral effort sensitivity
- **Consistency**: Results consistent across Bayesian, rmcorr, and subject-means approaches
- **Uncertainty**: Wide credible intervals reflect limited precision with N=39

## Quality Assurance

### Model Diagnostics
- **Convergence**: All models show R̂ < 1.01 and ESS > 400
- **Divergences**: Pooled models show <1% divergent transitions (acceptable)
- **Posterior predictive checks**: All models pass visual inspection

## Reproducibility Notes

### Version Information
- **R Version**: 4.0+ required
- **Analysis Date**: [Date when analyses were finalized]
- **Seed Setting**: All scripts use fixed seeds for reproducibility

### File Paths
Scripts use absolute paths that may need adjustment for different systems. Key paths to check:
- `BASE_DIR` in each script (default: `/Users/mohdasti/Documents/LC–YA`)
- Data directory paths (`100 Hz/`, `PI_Feedback_Outputs/`, etc.)

### Expected Runtime
- **Pupil Waveform Analysis**: ~2-5 minutes
- **AUC Bar Plots**: ~1-2 minutes
- **Individual Differences (Bayesian)**: ~10-15 minutes
- **Behavioral Plots**: ~1 minute

## Citation

If you use this analysis pipeline or reference these analyses, please cite:

[Manuscript citation - to be updated upon publication]

## Contributing

This repository contains the analysis code for a specific study. For questions, bug reports, or suggestions about the code, please open an issue in the repository.

## License

See [LICENSE](LICENSE) file for details. This analysis pipeline is provided for reproducibility purposes associated with the manuscript. Please refer to the manuscript for details on data usage and restrictions.

## Additional Documentation

For detailed workflow instructions, see:
- `Documentation/Analysis_Workflow.md` - Step-by-step analysis reproduction guide
- `Documentation/Data_Requirements.md` - Detailed data structure requirements
- `Documentation/Methodological_Notes.md` - Methodological decisions and rationale
- `05_Manuscript_Figures/Manuscript_Figures_Only/README.md` - Figure descriptions and captions

---

**Repository Version**: Final manuscript version  
**Last Updated**: January 2025













