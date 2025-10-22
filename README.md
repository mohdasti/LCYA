# LCYA: Locus Coeruleus - Young Adults Study

## Overview

This repository contains the supplementary materials and analysis code for the **LCYA (Locus Coeruleus - Young Adults)** study. The study investigates the **effects and interactions of concurrent physical and cognitive effort** on behavioral performance and pupillometric responses in younger adults.

## Study Design

### Main Research Question
How do concurrent **physical effort** (handgrip force) and **cognitive effort** (task difficulty) affect:
- **Behavioral performance** (accuracy, reaction time)
- **Physiological arousal** (pupil responses measured via AUC metrics)
- **Individual differences** in effort-related effects
- **Brain-behavior relationships**

### Tasks
Participants performed perceptual discrimination tasks under varying levels of physical and cognitive effort:

- **ADT** (Auditory Discrimination Task): Frequency discrimination with concurrent handgrip
- **VDT** (Visual Discrimination Task): Contrast discrimination with concurrent handgrip
- **CDT** (Change Detection Task): Arrow direction change detection with concurrent handgrip
- **MST** (Mnemonic Similarity Task): Memory-based similarity judgments

### Experimental Manipulations
- **Cognitive Effort**: Stimulus difficulty (Easy vs. Hard discrimination)
- **Physical Effort**: Handgrip force levels (Low: 5% MVC vs. High: 40% MVC)
- **Pupillometry**: Continuous pupil diameter measurement for arousal assessment

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
  - `LCYA_Final_Corrected_Analysis.R` → **MAIN SCRIPT** - Complete analysis pipeline (behavioral + physiological + brain-behavior + individual differences)
  - `LCYA_AUC_Analysis.R` → **PUPILLOMETRY ANALYSIS** - Area Under Curve metrics (Total AUC, Cognitive AUC, Physical AUC)
  - `Bivariate_Individual_Differences_brms.R` → Bayesian multivariate individual differences analysis
  - `Final_Individual_Differences_Verification.R` → Final verification of individual differences analysis
  - `response_bias_analysis.R` → Response bias analysis (Same/Different judgments)
- Additional reports:
  - `documentation/results_reports/PHYSIOLOGICAL_EFFECTS_ANALYSIS_SUMMARY.md`
  - `documentation/results_reports/FINAL_RESULTS_COMPARISON.md`

### Data Preprocessing
- `code/preprocessing/eyetracker_mat_to_csv_converter.m` - Convert individual MATLAB eyetracker files to CSV
- `code/preprocessing/batch_convert_eyetracker_files.m` - Batch conversion of all eyetracker files
- `code/preprocessing/README.md` - Detailed preprocessing documentation

### Plot Objects
- `code/plot_objects/ggplot_objects_ADT.R` - Auditory task visualizations
- `code/plot_objects/ggplot_objects_VDT.R` - Visual task visualizations
- `code/plot_objects/ggplot_objects_CDT.R` - Change detection task visualizations
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

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

This allows anyone to use, modify, and distribute the code with attribution.
