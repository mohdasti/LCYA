# Individual Differences Analysis: Verification Summary

## Problem Identified

**Issue:** The previous analysis using rmcorr with exactly 2 observations per subject produced a **mathematical artifact** where different effects (Physical vs Cognitive) yielded **identical correlation values**.

### Example of the Artifact:
For ADT Total AUC × Accuracy:
- Physical Effort: r_rm = -0.150, p = 0.355
- Cognitive Effort: r_rm = -0.150, p = 0.355 ← **IDENTICAL!**

This occurred despite the underlying data being genuinely different:
- Physical effects: mean pupil = -57.2, mean behavioral = -0.008
- Cognitive effects: mean pupil = -10.3, mean behavioral = -0.812

## Root Cause

**rmcorr with balanced 2-observation-per-subject designs** creates this artifact because:
1. Each subject has exactly 2 data points (e.g., Easy vs Hard)
2. The rmcorr model removes between-subject variance
3. With only 2 points per subject, the within-subject correlations become mathematically constrained
4. Different groupings (by difficulty vs by effort) yield identical correlation statistics

## Solution Implemented

**Subject Means Approach:**
1. Calculate difference scores (High - Low or Hard - Easy)
2. **Average to ONE value per subject** (e.g., average across difficulty levels)
3. Use Pearson correlation on these subject-level averaged scores

### Why This Works:
- Provides ONE data point per subject
- Avoids the rmcorr artifact
- Matches the original published analysis
- Interpretable as individual differences in effect magnitude

## Verification of Fix

### Original (Quoted) Stats:
- CDT Total AUC × Accuracy Physical: r = −.09, p = .59, n = 39
- ADT Total AUC × Accuracy Physical: r = −.06, p = .70, n = 39
- VDT Total AUC × Accuracy Physical: r = −.16, p = .35, n = 37
- ADT Cognitive AUC × Accuracy Cognitive: r = .13, p = .43, n = 39
- VDT Cognitive AUC × Accuracy Cognitive: r = −.07, p = .67, n = 37

### New Results (Subject Means):
- CDT Total AUC × Accuracy Physical: r = −.09, p = .59, n = 39 ✅ **MATCH**
- ADT Total AUC × Accuracy Physical: r = −.06, p = .70, n = 39 ✅ **MATCH**
- VDT Total AUC × Accuracy Physical: r = −.16, p = .35, n = 37 ✅ **MATCH**
- ADT Cognitive AUC × Accuracy Cognitive: r = .13, p = .43, n = 39 ✅ **MATCH**
- VDT Cognitive AUC × Accuracy Cognitive: r = −.07, p = .67, n = 37 ✅ **MATCH**

### Now Different (No More Artifact):
For ADT Total AUC × Accuracy:
- Physical Effort: r = −.06, p = .70, n = 39
- Cognitive Effort: r = .19, p = .25, n = 39 ← **DIFFERENT!**

## Files Generated

### New Directory:
`/Users/mohdasti/Documents/LC–YA/GitHub_Ready_Analyses/05_Manuscript_Figures/results_subject_means/`

### Key Files:
1. **individual_differences_subject_means_summary.csv** - Complete results table
2. **individual_differences_subject_means_report.md** - Comprehensive markdown report
3. **updated_manuscript_text.md** - Ready-to-use manuscript text
4. **[task]_[auc]_x_[behavior]_[effort]_effects_subject_means.csv** - Individual subject data (20 files)

### Script:
`/Users/mohdasti/Documents/LC–YA/GitHub_Ready_Analyses/03_Individual_Differences/Updated_Individual_Differences_Accuracy_RT_SubjectMeans.R`

## What Was Added

### New Analyses Beyond Original:
1. **Correct RT** (in addition to Accuracy)
2. **Physical Effort effects on Cognitive AUC** (previously skipped)

### Complete Coverage:
- Total AUC: Physical × Accuracy, Physical × RT, Cognitive × Accuracy, Cognitive × RT
- Cognitive AUC: Physical × Accuracy, Physical × RT, Cognitive × Accuracy, Cognitive × RT
- All 3 tasks: CDT, ADT, VDT (where appropriate)

## Recommendations

1. ✅ Use the **subject means approach** for reporting
2. ✅ Cite the **updated_manuscript_text.md** for manuscript text
3. ✅ All original stats are **verified and reproduced**
4. ✅ New analyses (RT, Physical on Cognitive AUC) add **complementary evidence**
5. ⚠️ The old rmcorr results should be **disregarded** due to the artifact

## Technical Note

This issue is specific to rmcorr with **balanced 2-observation designs**. With more observations per subject or unbalanced designs, rmcorr would not show this artifact. For individual differences with simple difference scores (one per subject per condition), the subject means approach is more appropriate and interpretable.

---

**Analysis Date:** 2025-11-09
**Verified By:** AI Analysis + Manual Cross-Check with Original Stats
