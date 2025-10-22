# Manuscript Analysis Scripts

This directory contains the R scripts that were verified to generate the results reported in the manuscript.

## Script Overview

### Individual Differences Analysis
- **`Bivariate_Individual_Differences_brms.R`**: Bayesian multivariate analysis of individual differences using brms. Generates `documentation/results_reports/Individual_Differences_Brms_Report.md`
- **`Final_Individual_Differences_Verification.R`**: Final verification of individual differences analysis using Total AUC and Cognitive AUC measures. Generates CSV outputs and summary in `documentation/results_reports/INDIVIDUAL_DIFFERENCES_FINAL_SUMMARY.md`

### Main Manuscript Analysis
- **`LCYA_Final_Corrected_Analysis.R`**: Complete manuscript analysis pipeline including behavioral effects, physiological effects (TEPR/AUCI), brain-behavior links, and individual differences. This is the primary analysis script that generates most manuscript results.

### Pupillometry Analysis
- **`LCYA_Lani_Corrected_Analysis.R`**: Implements the dual TEPR/AUCI approach to address methodological concerns. TEPR controls for physical effort, AUCI doesn't control for physical effort. Generates physiological effects results.
- **`LCYA_AUC_Analysis.R`**: Area Under Curve analysis for pupillometry metrics, including Total AUC and Cognitive AUC calculations.

## Usage

1. **For complete manuscript reproduction**: Run `LCYA_Final_Corrected_Analysis.R`
2. **For individual differences only**: Run `Bivariate_Individual_Differences_brms.R` and `Final_Individual_Differences_Verification.R`
3. **For pupillometry analysis**: Run `LCYA_Lani_Corrected_Analysis.R` and `LCYA_AUC_Analysis.R`

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
