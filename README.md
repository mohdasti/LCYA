# LCYA: Concurrent Effort in Younger Adults

[![DOI](https://zenodo.org/badge/750693548.svg)](https://doi.org/10.5281/zenodo.18204999)
[![ORCID](https://img.shields.io/badge/ORCID-0000--0001--7684--3731-a6ce39.svg)](https://orcid.org/0000-0001-7684-3731)
![License: GPLv3](https://img.shields.io/badge/License-GPLv3-blue.svg)
![R](https://img.shields.io/badge/R-4.5.1-blue.svg)
![GitHub top language](https://img.shields.io/github/languages/top/mohdasti/LCYA)

## Overview

This repository contains the analysis code and supplementary materials for:

> Dastgheib, M.\*, Sun, A. Y.\*, Yaghoubi, K. C., Zhang, W., Peters, M. A. K., Bennett, I. J., & Seitz, A. R. (in press). **Effects of concurrent task difficulty and physical effort on memory and perceptual performance and pupil response in younger adults.** _\*co-first authors_

The study examined effects of concurrent **task difficulty** (Easy vs. Hard stimulus similarity) and **physical effort** (Low 5% vs. High 40% MVC handgrip) on behavioral performance and pupillometric responses across three cognitive domains—visual working memory, auditory perception, and visual perception—in healthy younger adults (N = 38, M age = 22.9 years).

**Key findings:**
- Robust main effects of task difficulty on accuracy (all three tasks) and reaction time (perceptual tasks)
- Main effect of physical effort on reaction time for the visual perception task only
- Main effect of physical effort on pupillary response (Total AUC) for all three tasks
- Exploratory main effect of task difficulty on Cognitive AUC for the auditory perception task
- No interactions between task difficulty and physical effort for any outcome
- No significant individual-difference correlations between behavioral and pupillary effort effects

These findings suggest that task difficulty and physical effort influence performance and pupillary arousal through largely independent mechanisms in healthy younger adults.

## Study Design

### Tasks

Participants completed three experimental sessions, each involving a different cognitive task performed concurrently with an isometric handgrip at either Low (5% MVC) or High (40% MVC) force:

- **CDT** (Change Detection Task): Visual working memory — participants judged whether a probe arrow orientation matched a studied arrow. Task difficulty was manipulated by varying the rotation difference between studied and probe arrows (Easy: 45° or 90°; Hard: 5° or 20°).
- **ADT** (Auditory Discrimination Task): Auditory frequency discrimination — participants judged whether two sequential tones were the same or different. Task difficulty was manipulated by varying the frequency offset (Easy: +32 or +128 Hz; Hard: +4 or +8 Hz).
- **VDT** (Visual Discrimination Task): Visual contrast discrimination — participants judged whether two sequential Gabor patches were the same or different. Task difficulty was manipulated by varying the contrast offset (Easy: +0.16 or +0.32; Hard: +0.04 or +0.08).

### Physiological Measure

Pupil diameter was recorded continuously at 1000 Hz (EyeLink 1000, SR Research) and downsampled to 100 Hz. Two AUC metrics were computed:
- **Total AUC**: Integrated baseline-corrected pupil response from squeeze onset to response window onset
- **Cognitive AUC** (exploratory, ADT/VDT only): Integrated pupil response from 300 ms after target onset until response window onset, corrected to a pre-target baseline

## Repository Structure

```
LCYA/
├── analysis/
│   ├── main/                        # Full publication pipeline (R Markdown)
│   ├── manuscript_scripts/          # Scripts for individual analyses and figures
│   │   ├── figures/                 # Figure generation scripts (Figures 2–4)
│   │   └── *.R                      # Statistical analysis scripts
│   └── revision_analyses/           # Supplementary analyses added at revision
│       ├── *.R                      # Analysis scripts (numbered 01–05)
│       └── outputs/                 # Generated tables and figures
├── code/
│   ├── plot_objects/                # ggplot theme and task-specific plot templates
│   ├── preprocessing/               # Data preprocessing (MATLAB scripts, Python notebooks)
│   └── utilities/                   # Shared helper functions
├── documentation/
│   └── results_reports/             # Statistical summaries and reports
└── figures/
    └── publication/                 # Final publication-ready figures (PNG, 300 DPI)
```

## Key Analysis Scripts

### Primary Analyses

| Analysis | Script | Description |
|----------|--------|-------------|
| Full pipeline | `analysis/main/Aggregated_analysis_publication.Rmd` | Complete R Markdown pipeline reproducing all results |
| Behavioral + AUC models | `analysis/manuscript_scripts/LCYA_Final_Corrected_Analysis.R` | Primary GLMMs and LMMs for accuracy, RT, and pupil AUC |
| AUC models | `analysis/manuscript_scripts/LCYA_AUC_Analysis.R` | Focused LMM analysis for Total and Cognitive AUC |
| Individual differences | `analysis/manuscript_scripts/Bivariate_Individual_Differences_brms.R` | Bayesian multivariate models for behavior–pupil correlations |

### Manuscript Figures

| Figure | Script | Description | Output |
|--------|--------|-------------|--------|
| **Figure 2** – Behavioral performance | `analysis/revision_analyses/LCYA_Updated_Figures_Individual_Points.R` | Accuracy and RT by task difficulty × physical effort for CDT, ADT, VDT, with individual participant means and connecting lines | `figures/publication/Figure2_Task_Performance_Effects_Clean_Final.png` |
| **Figure 3** – Pupil waveforms | `analysis/manuscript_scripts/figures/LCYA_Isolated_Cognitive_AUC_Analysis.R` | GAM-smoothed pupil waveforms with pre-trial baseline and AUC windows annotated; CIs derived from subject-level means | `figures/publication/Figure3_Pupil_Waveforms.png` |
| **Figure 4** – AUC bar plots | `analysis/revision_analyses/LCYA_Merged_TotalCognitive_AUC_IndivPoints.R` | Merged Total AUC (all tasks) and Cognitive AUC (ADT/VDT) with individual data points | `figures/publication/Figure4_Merged_Total_Cognitive_AUC.png` |

**Figure 3 details:**
- Baseline: 500 ms pre-squeeze window (B₀)
- CDT: Total AUC only (Cognitive AUC excluded — probe presented during response window)
- ADT/VDT: Total AUC + Cognitive AUC shown; pre-stimulus baseline (B₂b) annotated

### Revision Analyses (`analysis/revision_analyses/`)

All scripts output tables to `analysis/revision_analyses/outputs/`.

| Script | Supplement | Description |
|--------|------------|-------------|
| `LCYA_Random_Slopes_Models.R` | Section 2 | Trial-level GLMMs (accuracy) and LMMs (RT, Total AUC, Cognitive AUC) with maximal random-effects structure (Barr et al., 2013) |
| `LCYA_TOST_Equivalence_Testing.R` | Section 3 | Two one-sided equivalence tests (TOST) for all non-significant interaction and PE main effects; SESOI anchored to Park et al. (2021), d = 0.79 |
| `LCYA_Grip_Force_Continuous_Models.R` | Section 4 | Models replacing binary Physical Effort with actual measured grip force (AUC/MVC, z-scored); includes motor-artifact check in High-effort trials |
| `LCYA_Confidence_Ratings_Analysis.R` | Section 1 | Trial-level LMMs for subjective confidence ratings (1–4 scale) across all tasks |
| `LCYA_Merged_TotalCognitive_AUC_IndivPoints.R` | Figure 4 | Generates Figure 4 (merged Total + Cognitive AUC bar plots with individual points) |
| `LCYA_Updated_Figures_Individual_Points.R` | Figure 2 | Generates Figure 2 (behavioral performance with individual data points) |

Key output files:
- `LCYA_FixedEffects_AllModels.csv` — fixed-effect estimates (b, SE, 95% CI, p) for all primary models (Supplementary Table S6)
- `LCYA_GripForce_FixedEffects.csv` — estimates from continuous grip force models (Supplementary Tables S4–S5)
- `LCYA_TOST_Results.csv` + `LCYA_TOST_ForestPlot.png` — equivalence test results (Supplementary Table S3 + Figure S2)
- `FigureS_ActualForce_vs_TotalAUC.png` — dose-response figure (Supplementary Figure S3)

## Dependencies

### R Packages

```r
install.packages(c(
  "tidyverse",   # data wrangling + ggplot2
  "lme4",        # mixed-effects models
  "lmerTest",    # p-values for LMMs
  "mgcv",        # GAM smoothing (Figure 3)
  "patchwork",   # combining plots
  "cowplot",     # plot assembly
  "viridis",     # color palettes
  "brms"         # Bayesian individual-differences models
))
```

R version used: 4.5.1

### Data Preprocessing

- **MATLAB** (`code/preprocessing/`): eyetracker file conversion
- **Python notebooks** (`code/preprocessing/python_notebooks/`): trial-level data aggregation per task

See `code/preprocessing/README.md` for preprocessing details.

## Usage

### Reproducing Manuscript Figures

1. Install all required R packages (see Dependencies)
2. Set `BASE_DIR` at the top of each script to point to your local data directory:
   ```r
   BASE_DIR <- "/path/to/your/LC-YA"
   ```
3. Run in order:
   ```r
   source("analysis/revision_analyses/LCYA_Updated_Figures_Individual_Points.R")
   source("analysis/manuscript_scripts/figures/LCYA_Isolated_Cognitive_AUC_Analysis.R")
   source("analysis/revision_analyses/LCYA_Merged_TotalCognitive_AUC_IndivPoints.R")
   ```

### Full Analysis Pipeline

```r
rmarkdown::render("analysis/main/Aggregated_analysis_publication.Rmd")
```

### Data Requirements

Raw data are not included (see Data Availability below). Scripts expect:

- **Pupil data**: `100 Hz/` directory containing `*_DS100_merged.csv` files with columns `sub`, `trial_index`, `time`, `pupil`, `duration_label`, `stimLev`, `isStrength`
- **Behavioral data**: `Complete_Manuscript_Results/complete_analysis_data.csv`

## Data Availability

De-identified behavioral and pupillometry data are available from the corresponding author upon reasonable request (subject to IRB/consent constraints). Analysis code and study materials are publicly available via Zenodo: https://doi.org/10.5281/zenodo.18204999

## Citation

```bibtex
@article{dastgheib2025concurrent,
  title   = {Effects of concurrent task difficulty and physical effort on memory
             and perceptual performance and pupil response in younger adults},
  author  = {Dastgheib, Mohammad and Sun, Andrew Y. and Yaghoubi, Kimia C. and
             Zhang, Weiwei and Peters, Megan A. K. and Bennett, Ilana J. and
             Seitz, Aaron R.},
  year    = {2025},
  note    = {in press}
}
```

## Contact

**Mohammad Dastgheib** — mdast003@ucr.edu  
University of California, Riverside

## License

This project is licensed under the GPLv3 License — see the [LICENSE](LICENSE) file for details.
