# LCYA: Veridicality and Other Measures

## Overview

This repository contains the supplementary materials and analysis code for the LCYA (Look-Change-Young-Adult) study investigating perceptual discrimination tasks and their relationship to memory and confidence measures.

## Study Design

The study includes four main perceptual discrimination tasks:
- **ADT** (Auditory Discrimination Task): Frequency discrimination
- **VDT** (Visual Discrimination Task): Contrast discrimination  
- **CDT** (Color Discrimination Task): Color discrimination
- **MST** (Memory Similarity Task): Memory-based similarity judgments

## Repository Structure

```
LCYA-Clean/
├── analysis/           # Main analysis files
│   └── main/          # Primary publication analysis
│   └── manuscript_scripts/  # Scripts verified to generate manuscript results
├── code/              # Analysis code
│   ├── plot_objects/  # ggplot object definitions
│   └── utilities/     # Helper functions and utilities
├── figures/           # Generated figures
│   └── publication/   # Publication-ready figures
└── documentation/     # Additional documentation
    └── results_reports/ # Markdown outputs matched to manuscript Results
```

## Key Files

### Main Analysis
- `analysis/main/Aggregated_analysis_publication.Rmd` - Complete analysis pipeline and results

### Manuscript-Verified Scripts and Reports

- Scripts used to generate manuscript Results are in `analysis/manuscript_scripts/`:
  - `Bivariate_Individual_Differences_brms.R` → writes `documentation/results_reports/Individual_Differences_Brms_Report.md`
  - `Final_Individual_Differences_Verification.R` → writes CSVs in `Final_Individual_Differences_Results/` and summarized in `documentation/results_reports/INDIVIDUAL_DIFFERENCES_FINAL_SUMMARY.md`
- Additional reports:
  - `documentation/results_reports/PHYSIOLOGICAL_EFFECTS_ANALYSIS_SUMMARY.md`
  - `documentation/results_reports/FINAL_RESULTS_COMPARISON.md`

### Plot Objects
- `code/plot_objects/ggplot_objects_ADT.R` - Auditory task visualizations
- `code/plot_objects/ggplot_objects_VDT.R` - Visual task visualizations
- `code/plot_objects/ggplot_objects_CDT.R` - Color task visualizations
- `code/plot_objects/ggplot_objects_MST.R` - Memory task visualizations
- `code/plot_objects/ggplot_objects_dist.R` - Distribution plots

### Utilities
- `code/utilities/export_plots.R` - Plot export functionality
- `code/utilities/plots_together.R` - Combined plot arrangements
- `code/utilities/MST_change_lures.R` - Memory task data processing

## Dependencies

The analysis requires the following R packages:
- `dplyr`, `ggplot2`, `tidyr` - Data manipulation and visualization
- `gridExtra`, `cowplot` - Plot arrangement
- `viridis`, `ggridges` - Advanced plotting
- `raincloudplots` - Distribution visualizations
- `report` - Statistical reporting

## Usage

1. Open `analysis/main/Aggregated_analysis_publication.Rmd` in RStudio
2. Install required packages if not already installed
3. Run the analysis chunks to reproduce results
4. Use utility scripts in `code/utilities/` for specific tasks

## Citation

If you use this code or data, please cite:
[Your paper citation will go here]

## Contact

Mohammad Dastgheib
mdast003@ucr.edu

## License

[Specify your license here]
