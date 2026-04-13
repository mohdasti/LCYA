# Analysis Workflow Documentation

## Overview
This document provides a detailed workflow for reproducing the LC-YA pupillometry analysis pipeline.

## Prerequisites

### System Requirements
- R version 4.0+ 
- Sufficient RAM (8GB+ recommended for Bayesian models)
- Multi-core processor (recommended for parallel MCMC chains)

### Data Structure
Ensure your data directory contains:
```
LC–YA/
├── PI_Feedback_Outputs/
│   └── Combined_Dual_AUC_Data.csv
├── Complete_Manuscript_Results/
│   └── complete_analysis_data.csv
├── 100 Hz/
│   ├── [pupil data files]
│   └── ...
└── GitHub_Ready_Analyses/
    └── [analysis scripts]
```

## Step-by-Step Workflow

### Step 1: Environment Setup
```r
# Install required packages (if not already installed)
required_packages <- c(
  "tidyverse", "brms", "rmcorr", "posterior", 
  "ggplot2", "patchwork", "mgcv", "lme4", "lmerTest"
)

install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg)
  }
}

sapply(required_packages, install_if_missing)

# Set working directory
setwd("/path/to/LC–YA/GitHub_Ready_Analyses")
```

### Step 2: Pupil Waveform Analysis
```r
# Navigate to pupil waveforms directory
setwd("01_Pupil_Waveforms")

# Run main analysis
source("LCYA_Isolated_Cognitive_AUC_Analysis.R")

# Expected outputs:
# - Figure3_Pupil_Waveforms.png (saved to 05_Manuscript_Figures/Manuscript_Figures_Only/)
# - Cognitive_Pupil_Waveforms_Publication_Ready_v2.png (saved to PI_Feedback_Outputs/)
# - Console output with LMM results
```

**Key Parameters**:
- Baseline window: -0.5s to 0s (500ms)
- Time range: -0.5s to response onset
- Smoothing: GAM with 95% CI
- CDT: Pre-trial Baseline and Total AUC only
- ADT/VDT: Pre-trial Baseline, Total AUC, Pre-stimulus Baseline, and Cognitive AUC

### Step 3: AUC Bar Plots
```r
# Navigate to AUC analyses directory
setwd("../02_AUC_Analyses")

# Generate bar plots
source("LCYA_Updated_Combined_AUC_Plots.R")

# Expected outputs:
# - Figure4_Total_AUC.png
# - Figure4_Cognitive_AUC.png
# (Note: Scripts save to various locations; check script outputs for exact paths)
```

**Key Features**:
- Separate plots for Total AUC and Cognitive AUC
- CDT cognitive AUC excluded per recommendations
- Publication-ready formatting

### Step 4: Individual Differences Analysis

#### 4a. Primary Analysis (Bayesian)
```r
# Navigate to individual differences directory
setwd("../03_Individual_Differences")

# Run primary Bayesian analysis
source("Bivariate_Individual_Differences_brms.R")

# Expected outputs:
# - results/primary_individual_differences_slope_correlations.csv
# - results/Individual_Differences_Brms_Report.md
# - models/ directory with .rds files
```

**Runtime**: ~10-15 minutes for all models
**Key Parameters**:
- Chains: 2-4 per model
- Iterations: 2000-5000 per chain
- adapt_delta: 0.95-0.99

#### 4b. Sensitivity Analysis (rmcorr)
```r
# Run rmcorr sensitivity analysis
source("Corrected_Individual_Differences_rmcorr.R")

# Expected outputs:
# - Corrected_rmcorr_Individual_Differences_Results/ directory
# - results/rmcorr_log.txt
```

#### 4c. Supplementary Analysis
```r
# Add missing Cognitive AUC subject-means
source("Add_Cognitive_AUC_Subject_Means.R")

# Expected outputs:
# - Updated results/rmcorr_log.txt
```

### Step 5: Behavioral Plots
```r
# Navigate to behavioral plots directory
setwd("../04_Behavioral_Plots")

# Generate behavioral performance plots
source("Figure2_Clean_Final_Version.R")

# Expected outputs:
# - Figure2_Task_Performance_Effects.png
# (saved to 05_Manuscript_Figures/Manuscript_Figures_Only/)
```

### Step 6: Results Compilation
```r
# Navigate to manuscript figures directory
setwd("../05_Manuscript_Figures")

# Review all outputs
list.files("results/", pattern = "*.csv|*.md|*.txt")
list.files("Manuscript_Figures_Only/", pattern = "*.png")
```

## Troubleshooting

### Common Issues

#### 1. Package Installation Errors
```r
# If brms installation fails:
install.packages("brms", dependencies = TRUE)

# If Stan compilation issues:
install.packages("cmdstanr")
cmdstanr::install_cmdstan()
```

#### 2. Memory Issues with Bayesian Models
```r
# Reduce model complexity:
# - Use fewer chains (chains = 2)
# - Reduce iterations (iter = 2000)
# - Increase adapt_delta for stability
```

#### 3. Convergence Warnings
```r
# Check model diagnostics:
summary(model_fit)
plot(model_fit)

# If divergences > 1%:
# - Increase adapt_delta to 0.99
# - Increase max_treedepth to 13
# - Check for data issues
```

#### 4. Data Path Issues
```r
# Verify data paths:
file.exists("../../PI_Feedback_Outputs/Combined_Dual_AUC_Data.csv")
file.exists("../../Complete_Manuscript_Results/complete_analysis_data.csv")

# Update paths if needed in scripts
```

### Performance Optimization

#### For Bayesian Models
```r
# Use cmdstanr backend (faster):
options(brms.backend = "cmdstanr")

# Parallel processing:
options(mc.cores = parallel::detectCores())

# Memory management:
gc()  # Run after each model
```

#### For Large Datasets
```r
# Data filtering:
# - Remove incomplete cases early
# - Use data.table for large datasets
# - Consider data sampling for exploration
```

## Quality Checks

### Model Diagnostics Checklist
- [ ] R̂ < 1.01 for all parameters
- [ ] ESS > 400 for all parameters  
- [ ] Divergences < 1% of draws
- [ ] Posterior predictive checks pass
- [ ] Trace plots show good mixing

### Results Validation
- [ ] Effect sizes are reasonable
- [ ] Confidence/credible intervals are appropriate
- [ ] Results consistent across methods
- [ ] Figures are publication-ready

### Reproducibility
- [ ] Fixed seeds used throughout
- [ ] Package versions documented
- [ ] All outputs saved with timestamps
- [ ] Code is well-commented

## Expected Runtime

| Analysis | Runtime | Notes |
|----------|---------|-------|
| Pupil Waveforms | 2-3 minutes | GAM fitting |
| AUC Bar Plots | 1-2 minutes | Quick plotting |
| Individual Differences (Bayesian) | 10-15 minutes | Multiple models |
| Individual Differences (rmcorr) | 1-2 minutes | Fast correlation |
| Behavioral Plots | 1-2 minutes | Quick plotting |
| **Total** | **15-25 minutes** | Full pipeline |

## Output Summary

### Key Files Generated
```
GitHub_Ready_Analyses/
├── 01_Pupil_Waveforms/
│   └── Cognitive_Pupil_Waveforms_Publication_Ready.png
├── 02_AUC_Analyses/
│   ├── Figure_Total_AUC_Publication_Ready.png
│   └── Figure_Cognitive_AUC_Publication_Ready.png
├── 03_Individual_Differences/
│   ├── results/
│   │   ├── primary_individual_differences_slope_correlations.csv
│   │   ├── Individual_Differences_Brms_Report.md
│   │   └── rmcorr_log.txt
│   └── models/ (Bayesian model objects)
├── 04_Behavioral_Plots/
│   └── Figure2_Task_Performance_Effects_Clean_Final.png
└── 05_Manuscript_Figures/
    ├── results/ (all analysis outputs)
    └── Complete_Manuscript_Plots/ (all figures)
```

### Manuscript-Ready Results
- **Figure 3**: Pupil waveforms (`Cognitive_Pupil_Waveforms_Publication_Ready.png`)
- **Figure 4**: AUC bar plots (Total and Cognitive AUC)
- **Figure 2**: Behavioral performance (`Figure2_Task_Performance_Effects_Clean_Final.png`)
- **Individual Differences**: Complete analysis report (`Individual_Differences_Brms_Report.md`)

## Support

For technical issues or questions about the analysis pipeline:
1. Check this documentation first
2. Review the troubleshooting section
3. Examine model diagnostics
4. Contact the analysis team

## Version History

- **v1.0**: Initial analysis pipeline
- **v1.1**: Added Bayesian individual differences analysis
- **v1.2**: Updated with publication-ready formatting
- **v1.3**: Added comprehensive documentation and quality checks













