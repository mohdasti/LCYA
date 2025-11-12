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
LCYA/
├── analysis/
│   ├── main/                          # Publication-scale R Markdown workflow
│   └── manuscript_scripts/
│       ├── figures/                   # Figure-specific generation scripts (Figures 2–4)
│       ├── Bivariate_Individual_Differences_brms.R
│       ├── Final_Individual_Differences_Verification.R
│       ├── LCYA_AUC_Analysis.R
│       ├── LCYA_Final_Corrected_Analysis.R
│       ├── Updated_Individual_Differences_Accuracy_RT_SubjectMeans.R
│       └── response_bias_analysis.R
├── code/
│   ├── plot_objects/                  # ggplot object definitions
│   ├── preprocessing/                 # Eyetracker preprocessing utilities
│   └── utilities/                     # Shared helper functions
├── documentation/
│   ├── ANALYSIS_OVERVIEW.md
│   ├── CODE_DOCUMENTATION.md
│   ├── REPOSITORY_STRUCTURE.md
│   └── results_reports/
│       ├── FINAL_RESULTS_COMPARISON.md
│       ├── INDIVIDUAL_DIFFERENCES_FINAL_SUMMARY.md
│       ├── Individual_Differences_Brms_Report.md
│       ├── PHYSIOLOGICAL_EFFECTS_ANALYSIS_SUMMARY.md
│       └── subject_means/
│           ├── ANALYSIS_COMPLETE_SUMMARY.md
│           ├── VERIFICATION_SUMMARY.md
│           └── results/
│               ├── individual_differences_subject_means_summary.csv
│               ├── individual_differences_subject_means_report.md
│               └── updated_manuscript_text.md
├── figures/
│   └── publication/                   # Publication-ready PNG exports
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

## Key Files

### Main Analysis
- `analysis/main/Aggregated_analysis_publication.Rmd` - Complete analysis pipeline and results

### Manuscript-Verified Scripts and Reports

The table below links each Results subsection and figure to the script that generated it:

| Result / Figure | Script | Key Outputs |
|-----------------|--------|-------------|
| Full manuscript pipeline | `analysis/manuscript_scripts/LCYA_Final_Corrected_Analysis.R` | Behavioral, physiological, and individual-differences statistics written to `documentation/results_reports/`. |
| Pupillometry AUC models | `analysis/manuscript_scripts/LCYA_AUC_Analysis.R` | Total, Cognitive, and Physical AUC model summaries. |
| Figure 2 – Task performance | `analysis/manuscript_scripts/figures/Figure2_Clean_Final_Version.R` | `figures/publication/Figure2_Task_Performance_Effects.png`. |
| Figure 3 – Pupil waveforms | `analysis/manuscript_scripts/figures/LCYA_Isolated_Cognitive_AUC_Analysis.R` | `figures/publication/Figure3_Pupil_Waveforms.png` plus LMM output. |
| Figure 4 – Total & Cognitive AUC bars | `analysis/manuscript_scripts/figures/LCYA_Updated_Combined_AUC_Plots.R` | `Figure4_Total_AUC.png`, `Figure4_Cognitive_AUC.png`. |
| Figure 4 – Combined layout | `analysis/manuscript_scripts/figures/LCYA_Figure4_Merged_AUC_Plot.R` | `Figure4_Merged_Total_Cognitive_AUC.png`. |
| Bayesian individual differences | `analysis/manuscript_scripts/Bivariate_Individual_Differences_brms.R` | `documentation/results_reports/Individual_Differences_Brms_Report.md`. |
| Subject-means individual differences | `analysis/manuscript_scripts/Updated_Individual_Differences_Accuracy_RT_SubjectMeans.R` | CSV + markdown in `documentation/results_reports/subject_means/results/`. |
| Frequentist verification | `analysis/manuscript_scripts/Final_Individual_Differences_Verification.R` | Confirms quoted correlations for Total & Cognitive AUC. |
| Response bias analysis | `analysis/manuscript_scripts/response_bias_analysis.R` | GLMM summary for Same/Different judgments. |

### Data Preprocessing
- `code/preprocessing/eyetracker_mat_to_csv_converter.m` - Convert individual MATLAB eyetracker files to CSV
- `code/preprocessing/batch_convert_eyetracker_files.m` - Batch conversion of all eyetracker files
- `code/preprocessing/README.md` - Detailed preprocessing documentation

### Figures

Publication-ready exports are bundled under `figures/publication/`:

| Figure | File | Generated by |
|--------|------|--------------|
| Figure 2 – Behavioral performance | `Figure2_Task_Performance_Effects.png` | `Figure2_Clean_Final_Version.R` |
| Figure 3 – Pupil waveforms | `Figure3_Pupil_Waveforms.png` | `LCYA_Isolated_Cognitive_AUC_Analysis.R` |
| Figure 4 – Total AUC | `Figure4_Total_AUC.png` | `LCYA_Updated_Combined_AUC_Plots.R` |
| Figure 4 – Cognitive AUC | `Figure4_Cognitive_AUC.png` | `LCYA_Updated_Combined_AUC_Plots.R` |
| Figure 4 – Combined layout | `Figure4_Merged_Total_Cognitive_AUC.png` | `LCYA_Figure4_Merged_AUC_Plot.R` |

## Dependencies

The analysis requires the following R packages:
- `dplyr`, `ggplot2`, `tidyr` - Data manipulation and visualization
- `gridExtra`, `cowplot` - Plot arrangement
- `viridis`, `ggridges` - Advanced plotting
- `raincloudplots` - Distribution visualizations
- `report` - Statistical reporting

## Usage

1. Install the required R packages (`tidyverse`, `lme4`, `lmerTest`, `brms`, `mgcv`, `patchwork`, `ggplot2`, etc.).
2. Set your working directory to the repository root.
3. Run `analysis/main/Aggregated_analysis_publication.Rmd` for the full reproduction, **or** execute the figure-specific scripts in `analysis/manuscript_scripts/figures/` to regenerate individual panels.
4. For the updated subject-means individual-differences analysis, run `analysis/manuscript_scripts/Updated_Individual_Differences_Accuracy_RT_SubjectMeans.R`; outputs land in `documentation/results_reports/subject_means/results/`.

## Citation

If you use this code or data, please cite:
[Your paper citation will go here]

## Contact

Mohammad Dastgheib
mdast003@ucr.edu

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

This allows anyone to use, modify, and distribute the code with attribution.
