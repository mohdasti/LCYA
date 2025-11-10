# Individual Differences Analysis: Subject Means Approach

**Analysis Date:** 2025-11-09 15:33:12.711093

## Overview

This analysis examines individual differences in pupillary and behavioral effort sensitivity
using **SUBJECT MEANS** approach with Pearson correlations.

### Key Features:
- ✅ Accuracy difference scores
- ✅ Correct RT difference scores
- ✅ Both Physical Effort (High - Low) and Cognitive Effort (Hard - Easy) effects
- ✅ Separate analyses for Total AUC and Cognitive AUC
- ✅ **Subject means approach:** ONE averaged value per subject to avoid rmcorr artifact

## Methods

**Statistical Approach:** Pearson correlation on subject-averaged difference scores

**Why Subject Means?**
- With exactly 2 observations per subject (e.g., Easy vs Hard), rmcorr produces
  mathematical artifacts where different effects yield identical correlations
- Subject means approach averages difference scores to ONE value per subject,
  providing a clean individual differences measure
- This matches the original analysis approach and published statistics

**Difference Scores Calculation:**

1. **Physical Effort effect (for each subject):**
   - Calculate High - Low for each difficulty level
   - Average across difficulty levels → ONE value per subject

2. **Cognitive Effort effect (for each subject):**
   - Calculate Hard - Easy for each effort level
   - Average across effort levels → ONE value per subject

**AUC Measures:**
- Total AUC: Overall pupillary response from squeeze onset to response
- Cognitive AUC: Isolated cognitive response (300ms post-stimulus to response, B2b baseline)

**Behavioral Measures:**
- Accuracy: Proportion correct
- Correct RT: Mean reaction time for correct trials only (ms)

---

## Results Summary Table

| Task | AUC Measure | Behavioral Measure | Effort Type | r | 95% CI | p | n |
|------|-------------|--------------------|--------------|----|--------|---|---|
| CDT | Total AUC | Accuracy | Physical | -0.09 | [-0.39, 0.23] | 0.59 | 39 |
| CDT | Total AUC | Accuracy | Cognitive | — | — | — | — |
| ADT | Total AUC | Accuracy | Physical | -0.06 | [-0.37, 0.26] | 0.70 | 39 |
| ADT | Total AUC | Accuracy | Cognitive | 0.19 | [-0.13, 0.48] | 0.25 | 39 |
| VDT | Total AUC | Accuracy | Physical | -0.16 | [-0.46, 0.17] | 0.35 | 37 |
| VDT | Total AUC | Accuracy | Cognitive | 0.07 | [-0.26, 0.39] | 0.66 | 37 |
| CDT | Total AUC | Correct RT | Physical | -0.00 | [-0.32, 0.31] | 0.98 | 39 |
| CDT | Total AUC | Correct RT | Cognitive | — | — | — | — |
| ADT | Total AUC | Correct RT | Physical | -0.07 | [-0.38, 0.25] | 0.66 | 39 |
| ADT | Total AUC | Correct RT | Cognitive | 0.25 | [-0.09, 0.54] | 0.14 | 35 |
| VDT | Total AUC | Correct RT | Physical | -0.08 | [-0.39, 0.25] | 0.66 | 37 |
| VDT | Total AUC | Correct RT | Cognitive | 0.04 | [-0.29, 0.36] | 0.82 | 37 |
| ADT | Cognitive AUC | Accuracy | Physical | -0.07 | [-0.38, 0.25] | 0.68 | 39 |
| ADT | Cognitive AUC | Accuracy | Cognitive | 0.13 | [-0.19, 0.43] | 0.43 | 39 |
| VDT | Cognitive AUC | Accuracy | Physical | -0.08 | [-0.40, 0.25] | 0.63 | 37 |
| VDT | Cognitive AUC | Accuracy | Cognitive | -0.07 | [-0.39, 0.26] | 0.67 | 37 |
| ADT | Cognitive AUC | Correct RT | Physical | -0.12 | [-0.42, 0.20] | 0.46 | 39 |
| ADT | Cognitive AUC | Correct RT | Cognitive | 0.28 | [-0.06, 0.56] | 0.10 | 35 |
| VDT | Cognitive AUC | Correct RT | Physical | -0.06 | [-0.38, 0.27] | 0.71 | 37 |
| VDT | Cognitive AUC | Correct RT | Cognitive | 0.03 | [-0.30, 0.35] | 0.88 | 37 |

---

## Detailed Results by Analysis

### Total AUC × Accuracy

**CDT:**
- Physical Effort: *r* = -0.09, 95% CI [-0.39, 0.23], *p* = 0.59, *n* = 39
- Cognitive Effort: Skipped

**ADT:**
- Physical Effort: *r* = -0.06, 95% CI [-0.37, 0.26], *p* = 0.70, *n* = 39
- Cognitive Effort: *r* = 0.19, 95% CI [-0.13, 0.48], *p* = 0.25, *n* = 39

**VDT:**
- Physical Effort: *r* = -0.16, 95% CI [-0.46, 0.17], *p* = 0.35, *n* = 37
- Cognitive Effort: *r* = 0.07, 95% CI [-0.26, 0.39], *p* = 0.66, *n* = 37


### Total AUC × Correct RT

**CDT:**
- Physical Effort: *r* = -0.00, 95% CI [-0.32, 0.31], *p* = 0.98, *n* = 39
- Cognitive Effort: Skipped

**ADT:**
- Physical Effort: *r* = -0.07, 95% CI [-0.38, 0.25], *p* = 0.66, *n* = 39
- Cognitive Effort: *r* = 0.25, 95% CI [-0.09, 0.54], *p* = 0.14, *n* = 35

**VDT:**
- Physical Effort: *r* = -0.08, 95% CI [-0.39, 0.25], *p* = 0.66, *n* = 37
- Cognitive Effort: *r* = 0.04, 95% CI [-0.29, 0.36], *p* = 0.82, *n* = 37


### Cognitive AUC × Accuracy

**ADT:**
- Physical Effort: *r* = -0.07, 95% CI [-0.38, 0.25], *p* = 0.68, *n* = 39
- Cognitive Effort: *r* = 0.13, 95% CI [-0.19, 0.43], *p* = 0.43, *n* = 39

**VDT:**
- Physical Effort: *r* = -0.08, 95% CI [-0.40, 0.25], *p* = 0.63, *n* = 37
- Cognitive Effort: *r* = -0.07, 95% CI [-0.39, 0.26], *p* = 0.67, *n* = 37


### Cognitive AUC × Correct RT

**ADT:**
- Physical Effort: *r* = -0.12, 95% CI [-0.42, 0.20], *p* = 0.46, *n* = 39
- Cognitive Effort: *r* = 0.28, 95% CI [-0.06, 0.56], *p* = 0.10, *n* = 35

**VDT:**
- Physical Effort: *r* = -0.06, 95% CI [-0.38, 0.27], *p* = 0.71, *n* = 37
- Cognitive Effort: *r* = 0.03, 95% CI [-0.30, 0.35], *p* = 0.88, *n* = 37


---

## Interpretation Notes

### Findings
Most correlations did not reach statistical significance, suggesting that:
- Individual differences in physiological effort sensitivity (AUC) do not strongly predict
  individual differences in behavioral effort sensitivity (accuracy or RT)
- This pattern holds across both accuracy and RT measures
- This pattern is consistent for both physical effort and cognitive effort manipulations

### Cognitive AUC Notes
- CDT excluded per analytical recommendations (difficulty manipulation issues)
- ADT and VDT analyzed for both Physical and Cognitive effort effects
- Physical effort effects on Cognitive AUC test whether the isolated cognitive response
  still shows individual differences related to the physical manipulation

### RT vs Accuracy
The inclusion of Correct RT provides a complementary measure to accuracy:
- Accuracy reflects decision correctness
- Correct RT reflects processing speed (on successful trials)
- Together, they provide a more complete picture of behavioral performance

### Methodological Note: Subject Means vs rmcorr
This analysis uses the **subject means approach** rather than rmcorr because:
- With exactly 2 observations per subject, rmcorr produces mathematical artifacts
- Different effects (physical vs cognitive) yielded identical r values in rmcorr
- Subject means (one averaged value per subject) provides clean individual differences
- This approach matches the original published analysis

---

## Files Generated

### Summary:
- `individual_differences_subject_means_summary.csv` - Complete results table

### Individual Difference Scores (Subject Means):
Format: `{task}_{auc_measure}_x_{behavioral_measure}_{effort_type}_effects_subject_means.csv`

Each file contains ONE averaged difference score per subject used in the correlation analyses.

---

**End of Report**
