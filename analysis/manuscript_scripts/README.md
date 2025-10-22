# Manuscript Analysis Scripts

This directory contains the R scripts that were verified to generate the results reported in the manuscript.

## Script Overview

### Main Analysis Pipeline
- **`LCYA_Final_Corrected_Analysis.R`**: **MAIN SCRIPT** - Complete manuscript analysis pipeline including all Results subsections:
  - Behavioral effects (accuracy, reaction time)
  - Physiological effects (AUC metrics)
  - Brain-behavior relationships (moderation analysis)
  - Individual differences

### Pupillometry Analysis
- **`LCYA_AUC_Analysis.R`**: **PUPILLOMETRY ANALYSIS** - Area Under Curve analysis for pupillometry metrics:
  - **Total AUC** (0.5 to 5.5 seconds) - Combined physical + cognitive arousal
  - **Cognitive AUC** (task-specific windows) - Cognitive processing effects
  - **Physical AUC** (1.5 to 3.5 seconds) - Physical effort effects

### Individual Differences Analysis
- **`Bivariate_Individual_Differences_brms.R`**: Bayesian multivariate analysis of individual differences using brms. Generates `documentation/results_reports/Individual_Differences_Brms_Report.md`
- **`Final_Individual_Differences_Verification.R`**: Final verification of individual differences analysis using Total AUC and Cognitive AUC measures. Generates CSV outputs and summary in `documentation/results_reports/INDIVIDUAL_DIFFERENCES_FINAL_SUMMARY.md`

### Response Bias Analysis
- **`response_bias_analysis.R`**: Analysis of response bias (Same/Different judgments) across tasks using GLMM models.

## Results Section Coverage

✅ **Behavioral Effects**: Accuracy and reaction time models (GLMM/LMM)
✅ **Physiological Effects**: AUC pupillometry models (Total AUC, Cognitive AUC, Physical AUC)
✅ **Brain-Behavior Relationships**: Moderation analysis (GLMM)
✅ **Individual Differences**: Subject-level correlations (Bayesian + frequentist)
✅ **Response Bias**: Same/Different judgment analysis (GLMM)

## Usage

1. **For complete manuscript reproduction**: Run `LCYA_Final_Corrected_Analysis.R`
2. **For pupillometry analysis**: Run `LCYA_AUC_Analysis.R`
3. **For individual differences only**: Run `Bivariate_Individual_Differences_brms.R` and `Final_Individual_Differences_Verification.R`
4. **For response bias**: Run `response_bias_analysis.R`

## Dependencies

All scripts require:
- `tidyverse`, `lme4`, `lmerTest`, `broom.mixed`
- `brms` (for Bayesian analysis)
- `ggplot2`, `patchwork` (for visualization)

## Outputs

Scripts generate:
- CSV files with analysis results
- Markdown reports in `documentation/results_reports/`
- Statistical model outputs
- Diagnostic plots and summaries
