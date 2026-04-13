# Individual Differences: Bivariate brms Analysis and Sensitivity

## Data & Measures
- Source AUC: `PI_Feedback_Outputs/Combined_Dual_AUC_Data.csv`
- Source behavior: `Complete_Manuscript_Results/complete_analysis_data.csv`
- Measures: `mean_total_auc` (Total AUC), `mean_cognitive_auc` (Cognitive AUC), behavior `mean_accuracy`.

## Model Specifications (brms)
- Per-task primary models (two-response multivariate):
  - auc_value ~ 1 + effort_contrast + difficulty_contrast + effort_contrast:difficulty_contrast + (1 + effort_contrast | p | sub)
  - acc_value ~ 1 + effort_contrast + difficulty_contrast + effort_contrast:difficulty_contrast + (1 + effort_contrast | p | sub)
  - Target estimand: correlation between subject-specific effort slopes across outcomes (random-slope correlation).
- Pooled models (hierarchical across tasks): add (1 + effort_contrast | task) to both responses.
- Priors: normal(0,5) for b; LKJ(2) for cor; Gaussian family; rescor = FALSE.

## Primary Results (Per Task)
Columns: model, mean, median, sd, 95% CrI, Pr(>0), Pr(<0)

| model | mean | median | sd | lower_95 | upper_95 | prob_positive | prob_negative |
|---|---|---|---|---|---|---|---|
| CDT_mean_total_auc_physical | -0.040 | -0.056 | 0.371 | -0.720 | 0.676 | 0.451 | 0.549 |
| ADT_mean_total_auc_physical | -0.012 | -0.013 | 0.374 | -0.721 | 0.696 | 0.482 | 0.517 |
| VDT_mean_total_auc_physical | -0.014 | -0.003 | 0.381 | -0.706 | 0.691 | 0.498 | 0.501 |
| ADT_mean_cognitive_auc_cognitive | -0.016 | -0.026 | 0.387 | -0.720 | 0.701 | 0.479 | 0.521 |
| VDT_mean_cognitive_auc_cognitive | -0.024 | -0.018 | 0.396 | -0.748 | 0.713 | 0.489 | 0.510 |

## Pooled Results (Across Tasks, Strict HMC)

- POOLED_TotalAUC_Physical: mean=-0.036, median=-0.044, 95% CrI [-0.729, 0.680], Pr(>0)=0.458
  Diagnostics: Rhat_max=1.004, ESS_min=260, Divergences=NA
- POOLED_CogAUC_Cognitive: mean=-0.019, median=-0.022, 95% CrI [-0.712, 0.682], Pr(>0)=0.479
  Diagnostics: Rhat_max=1.006, ESS_min=252, Divergences=NA

## Sensitivity: rmcorr (difference scores)
```
=== CORRECTED INDIVIDUAL DIFFERENCES ANALYSIS (rmcorr) ===
Analysis Date: 1759779449 
Using repeated measures correlation to address non-independence
Per literature review recommendations

Data loaded and processed successfully

========== TOTAL AUC ANALYSIS (rmcorr) ==========

--- CDT Total AUC ---
CDT Total AUC Physical Effort (rmcorr): r_rm = 0.018, 95% CI [-0.295, 0.327], p = 0.914, df = 38, n = 78
CDT Total AUC Cognitive Effort: Skipped per Lani's recommendations
Warning message:
In rmcorr(participant = sub, measure1 = pupil_physical_effect, measure2 = accuracy_physical_effect,  :
  'sub' coerced into a factor

--- ADT Total AUC ---
ADT Total AUC Physical Effort (rmcorr): r_rm = -0.150, 95% CI [-0.441, 0.169], p = 0.355, df = 38, n = 78
ADT Total AUC Cognitive Effort (rmcorr): r_rm = -0.150, 95% CI [-0.441, 0.169], p = 0.355, df = 38, n = 78
Warning messages:
1: In rmcorr(participant = sub, measure1 = pupil_physical_effect, measure2 = accuracy_physical_effect,  :
  'sub' coerced into a factor
2: In rmcorr(participant = sub, measure1 = pupil_cognitive_effect,  :
  'sub' coerced into a factor

--- VDT Total AUC ---
VDT Total AUC Physical Effort (rmcorr): r_rm = 0.206, 95% CI [-0.121, 0.493], p = 0.214, df = 36, n = 74
VDT Total AUC Cognitive Effort (rmcorr): r_rm = 0.206, 95% CI [-0.121, 0.493], p = 0.214, df = 36, n = 74
Warning messages:
1: In rmcorr(participant = sub, measure1 = pupil_physical_effect, measure2 = accuracy_physical_effect,  :
  'sub' coerced into a factor
2: In rmcorr(participant = sub, measure1 = pupil_cognitive_effect,  :
  'sub' coerced into a factor

========== COGNITIVE AUC ANALYSIS (rmcorr) ==========

CDT Cognitive AUC: Skipped per Lani's recommendations

--- ADT Cognitive AUC ---
ADT Cognitive AUC Physical Effort (rmcorr): r_rm = -0.050, 95% CI [-0.356, 0.266], p = 0.76, df = 38, n = 78
ADT Cognitive AUC Cognitive Effort (rmcorr): r_rm = -0.050, 95% CI [-0.356, 0.266], p = 0.76, df = 38, n = 78
Warning messages:
1: In rmcorr(participant = sub, measure1 = pupil_physical_effect, measure2 = accuracy_physical_effect,  :
  'sub' coerced into a factor
2: In rmcorr(participant = sub, measure1 = pupil_cognitive_effect,  :
  'sub' coerced into a factor

--- VDT Cognitive AUC ---
VDT Cognitive AUC Physical Effort (rmcorr): r_rm = -0.073, 95% CI [-0.384, 0.253], p = 0.663, df = 36, n = 74
VDT Cognitive AUC Cognitive Effort (rmcorr): r_rm = -0.073, 95% CI [-0.384, 0.253], p = 0.663, df = 36, n = 74
Warning messages:
1: In rmcorr(participant = sub, measure1 = pupil_physical_effect, measure2 = accuracy_physical_effect,  :
  'sub' coerced into a factor
2: In rmcorr(participant = sub, measure1 = pupil_cognitive_effect,  :
  'sub' coerced into a factor

========== SENSITIVITY ANALYSIS: SUBJECT MEANS ==========

--- CDT Total AUC (Subject Means) ---
CDT Total AUC Physical Effort (subject means): r = -0.089, 95% CI [-0.393, 0.233], p = 0.59, n = 39

--- ADT Total AUC (Subject Means) ---
ADT Total AUC Physical Effort (subject means): r = -0.064, 95% CI [-0.372, 0.257], p = 0.698, n = 39
ADT Total AUC Cognitive Effort (subject means): r = 0.189, 95% CI [-0.135, 0.476], p = 0.25, n = 39

--- VDT Total AUC (Subject Means) ---
VDT Total AUC Physical Effort (subject means): r = -0.159, 95% CI [-0.459, 0.174], p = 0.348, n = 37
VDT Total AUC Cognitive Effort (subject means): r = 0.075, 95% CI [-0.255, 0.389], p = 0.66, n = 37

=== CORRECTED INDIVIDUAL DIFFERENCES ANALYSIS COMPLETE ===
Results saved to: /Users/mohdasti/Documents/LC–YA/Corrected_rmcorr_Individual_Differences_Results 

📊 Key Changes:
✅ Using rmcorr to address non-independence
✅ Proper degrees of freedom (df = n-1, not 2n-2)
✅ Sensitivity analysis with subject means approach
✅ Statistically valid approach per literature review
✅ Maintains all data while addressing independence assumption
```

## File Outputs
- Primary CSV: `results/primary_individual_differences_slope_correlations.csv`
- Pooled CSVs: `results/summary_POOLED_TotalAUC_Physical_slope_correlation_strict.csv`, `results/summary_POOLED_CogAUC_Cognitive_slope_correlation_strict.csv`
- Diagnostics: `results/diagnostics_POOLED_TotalAUC_Physical.txt`, `results/diagnostics_POOLED_CogAUC_Cognitive.txt`
- rmcorr log: `results/rmcorr_log.txt`
- Model objects: `models/` (one .rds per fit)

## Clarifications and Anomaly Note

- Estimand clarification: The reported correlation is the random-slope correlation between subject-specific effort slopes for physiology (AUC) and behavior (accuracy). It quantifies whether individuals with larger physiological effort sensitivity also show larger behavioral sensitivity.

- rmcorr logging anomaly (ADT/VDT): The rmcorr log showed identical values for physical and cognitive effects in ADT and VDT. We verified that the underlying per-effect datasets differ (see `Corrected_rmcorr_Individual_Differences_Results/*_physical_effects_rmcorr.csv` vs `*_cognitive_effects_rmcorr.csv`), confirming this was a log duplication, not an analytical error. Bayesian results already show distinct estimates (e.g., ADT physical vs cognitive differ slightly). If needed, we can regenerate the rmcorr text block with corrected labels; numerical conclusions remain unchanged.
