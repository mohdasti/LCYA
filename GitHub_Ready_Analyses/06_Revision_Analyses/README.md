# LCYA Revision Analyses

Scripts in this folder implement all new analyses committed to in the response to reviewers (*Cognitive Research: Principles and Implications*, submission March 2026). Each subfolder corresponds to a specific reviewer commitment and is fully self-contained.

**Run scripts in order (01 → 02 → 03 → 04 → 05)** — Script 02 reads the output of Script 01.

---

## Directory Structure

```
06_Revision_Analyses/
├── 01_Random_Slopes_Models/          R1 Major #2 + R1 Minor #3
├── 02_TOST_Equivalence_Testing/      R1 Major #2
├── 03_Continuous_Grip_Force/         R1 Major #3
├── 04_Confidence_Ratings/            R2 #5
└── 05_Updated_Figures/               R1 Minor #4 + R1 Minor #2
```

---

## 01 — Random Slopes Models

**Script:** `LCYA_Random_Slopes_Models.R`  
**Reviewer:** R1 Major #2, R1 Minor #3

Re-runs all GLMMs (accuracy) and LMMs (RT, Total AUC, Cognitive AUC) at the **trial level** with a maximal random-effects structure (random slopes for Task Difficulty, Physical Effort, and their interaction; Barr et al., 2013). If the maximal model fails to converge, a principled reduction sequence is applied (Bates et al., 2015; Brauer & Curtin, 2018): uncorrelated slopes → random intercept only. The final random-effects structure is logged for each model.

Also produces the **comprehensive fixed-effects table** (b, SE, 95% Wald CI, z/t, p) for **all** effects — including all non-significant ones — required for the revised Supplementary Material.

**Key outputs:**
- `outputs/LCYA_FixedEffects_AllModels.csv` — comprehensive results table (feed into Script 02)
- `outputs/LCYA_RandomEffects_Structure.csv` — final RE structure per model
- `outputs/LCYA_Model_Summaries.txt` — full lme4 model summaries

---

## 02 — TOST Equivalence Testing

**Script:** `LCYA_TOST_Equivalence_Testing.R`  
**Reviewer:** R1 Major #2

Runs Two One-Sided Tests (TOST; Lakens, 2018) for all non-significant interaction and Physical Effort main effects across behavioral and pupil outcomes.

### ⚠️ Action required before running

Open the script and set `SESOI_PARK2021_B` at the top to the unstandardised regression coefficient for the Task Difficulty × Physical Effort interaction on RT from **Park et al. (2021)**, which is the SESOI anchor. This is the smallest effect size that would be considered theoretically meaningful for this paradigm.

For outcomes where Park et al. did not report an effect (accuracy, AUC), a secondary bound of Cohen's d = 0.2 (small effect) is used.

**Key outputs:**
- `outputs/LCYA_TOST_Results.csv` — equivalence decisions per effect
- `outputs/LCYA_TOST_ForestPlot.pdf/.png` — forest plot of effects vs. SESOI bounds
- `outputs/LCYA_TOST_Summary.txt` — narrative summary

---

## 03 — Continuous Grip Force Models

**Script:** `LCYA_Grip_Force_Continuous_Models.R`  
**Reviewer:** R1 Major #3

Uses **instructed** trial-by-trial target force (`gf_trPer`, proportion of MVC) as `gf_scaled` in Sets A–B. **Set C** uses **measured** exerted force per trial, `auc_rel_mvc` (grip-force AUC ÷ participant MVC from preprocessing), z-scored within High-effort trials only (`auc_scaled`), so the effect is interpretable when the instructed level is fixed at 0.40 MVC.

| Set | Predictor | Purpose |
|-----|-----------|---------|
| A | `gf_scaled` | Instructed force → accuracy / RT |
| B | `gf_scaled` | Instructed force → Total AUC (all trials) |
| C | `auc_scaled` (from `auc_rel_mvc`, High only) | Measured force → Total AUC within High effort (motor-artifact test) |
| D | `log_rt_scaled` × effort | RT as cognitive effort proxy in pupil model |

Model Set C directly tests the **motor artifact** concern using **trial-wise variation in actual squeeze magnitude** (not the binary Low/High label).

**Key outputs:**
- `outputs/LCYA_GripForce_FixedEffects.csv`
- `outputs/LCYA_GripForce_ModelC_SanityChecks.txt` — variance checks for Model C
- `outputs/LCYA_GripForce_DosePlot.pdf/.png` — instructed gf vs. Total AUC dose-response
- `outputs/LCYA_GripForce_ModelC_HighOnly_aucRelMVC.pdf/.png` — measured force vs. Total AUC (High trials)
- `outputs/LCYA_RT_Pupil_Plot.pdf/.png` — log RT vs. Total AUC scatterplot

---

## 04 — Confidence Ratings

**Script:** `LCYA_Confidence_Ratings_Analysis.R`  
**Reviewer:** R2 #5

Analyzes trial-level confidence ratings (`conf_median`, 4-point scale) using two complementary models:
- **LMM** — treating confidence as continuous (consistent with main analysis framework)
- **CLMM** — cumulative-link mixed model (`ordinal` package) respecting ordinal structure

Both models include Task Difficulty × Physical Effort with random slopes.

Produces bar plots with individual data points (matching the revised Figure 2 style) for inclusion in the Results alongside accuracy and RT.

**Key outputs:**
- `outputs/LCYA_Confidence_FixedEffects.csv`
- `outputs/LCYA_Confidence_BarPlot.pdf/.png`
- `outputs/LCYA_Confidence_IndividualPoints.pdf/.png`

---

## 05 — Updated Figures

**Script:** `LCYA_Updated_Figures_Individual_Points.R`  
**Reviewer:** R1 Minor #4, R1 Minor #2

Produces revised versions of all main figures with **individual participant data points** (jittered, semi-transparent dots) overlaid on group mean bars, with connecting lines linking the same participant across conditions (per difficulty, within each effort level).

Also produces **Supplementary Figure S1** for Cognitive AUC (ADT + VDT only), relocated from the main text per Reviewer 1, Minor #2.

**Key outputs:**
- `outputs/Figure2_Revised_Behavioral_IndivPoints.pdf/.png`
- `outputs/Figure4_Revised_TotalAUC_IndivPoints.pdf/.png`
- `outputs/FigureS1_CognitiveAUC_Supplementary.pdf/.png`

---

## Dependencies

All scripts require:
```r
tidyverse, lme4, lmerTest, broom.mixed, ggplot2, patchwork
```

Script 04 additionally requires:
```r
ordinal
```

Install missing packages with:
```r
install.packages(c("tidyverse", "lme4", "lmerTest", "broom.mixed",
                   "ggplot2", "patchwork", "ordinal"))
```

---

## Data

All scripts read from:
```
/Users/mohdasti/Documents/LC–YA/100 Hz/*_DS100_merged.csv
```

The merged CSV files contain pupil time-series data (100 Hz) with trial-level metadata (accuracy, RT, grip force, confidence, AUC) merged in. One file per subject per task.

---

## Reviewer–Script Cross-Reference

| Reviewer Comment | Script |
|---|---|
| R1 Major #2 — comprehensive reporting of all fixed effects | 01, 02 |
| R1 Major #2 — equivalence testing with grounded SESOI | 02 |
| R1 Major #3 — trial-by-trial grip force + RT as cognitive proxy | 03 |
| R1 Minor #2 — Cognitive AUC to Supplementary Material | 05 |
| R1 Minor #3 — random slopes for all within-subjects predictors | 01 |
| R1 Minor #4 — individual data points on Figures 2 and 4 | 05 |
| R2 #5 — confidence ratings analysis | 04 |
