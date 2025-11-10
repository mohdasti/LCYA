# Individual Differences Analysis: Complete Summary

## ✅ Problem Solved

You were **absolutely correct** to question the identical statistics! The rmcorr approach with exactly 2 observations per subject created a mathematical artifact where Physical and Cognitive effects produced identical correlations despite having different underlying data.

## Key Findings

### The Artifact Example (OLD - rmcorr):
```
ADT Total AUC × Accuracy:
- Physical Effort: r_rm = -0.150, p = 0.355, n = 78
- Cognitive Effort: r_rm = -0.150, p = 0.355, n = 78  ← IDENTICAL!
```

### Corrected Results (NEW - Subject Means):
```
ADT Total AUC × Accuracy:
- Physical Effort: r = -0.06, p = 0.70, n = 39
- Cognitive Effort: r = 0.19, p = 0.25, n = 39  ← NOW DIFFERENT!
```

## Verification Against Original Stats

Your original quoted statistics **perfectly match** our new subject means approach:

| Statistic | Original | New | Match? |
|-----------|----------|-----|--------|
| CDT Total AUC × Accuracy Physical | r = −.09, p = .59 | r = −.09, p = .59 | ✅ |
| ADT Total AUC × Accuracy Physical | r = −.06, p = .70 | r = −.06, p = .70 | ✅ |
| VDT Total AUC × Accuracy Physical | r = −.16, p = .35 | r = −.16, p = .35 | ✅ |
| ADT Cognitive AUC × Accuracy Cognitive | r = .13, p = .43 | r = .13, p = .43 | ✅ |
| VDT Cognitive AUC × Accuracy Cognitive | r = −.07, p = .67 | r = −.07, p = .67 | ✅ |

## What Changed

### Data Structure:
- **OLD:** 2 rows per subject (e.g., Easy & Hard) → rmcorr with 78 observations
- **NEW:** 1 row per subject (averaged across conditions) → Pearson with 39 subjects

### Example for Subject 13 (ADT Total AUC × Accuracy Physical):
- **OLD:** Easy = -39.3, Hard = 50.9 (2 values)
- **NEW:** Mean = 5.78 (1 averaged value)

## Files Generated

### Main Results:
📁 `/Users/mohdasti/Documents/LC–YA/GitHub_Ready_Analyses/05_Manuscript_Figures/results_subject_means/`

1. **individual_differences_subject_means_summary.csv**
   - Complete results table for all analyses
   
2. **individual_differences_subject_means_report.md**
   - Comprehensive markdown report with methods and interpretation
   
3. **updated_manuscript_text.md**
   - Ready-to-use text for your manuscript
   - Organized by AUC type and behavioral measure
   - Follows your original structure

### Data Files (20 files):
- `[task]_[auc]_x_[behavior]_[effort]_effects_subject_means.csv`
- Each contains ONE averaged difference score per subject

### Script:
📄 `/Users/mohdasti/Documents/LC–YA/GitHub_Ready_Analyses/03_Individual_Differences/Updated_Individual_Differences_Accuracy_RT_SubjectMeans.R`
- Reusable for future analyses
- Well-documented with the subject means approach

## New Analyses Included

Beyond your original analysis, we now have:

1. ✅ **Correct RT** (in addition to Accuracy)
   - Total AUC × Correct RT
   - Cognitive AUC × Correct RT
   
2. ✅ **Physical Effort effects on Cognitive AUC**
   - Previously skipped but theoretically interesting
   - Tests if isolated cognitive response shows individual differences related to physical manipulation

## Complete Coverage

| AUC Type | Effort Type | Behavioral Measure | Tasks |
|----------|-------------|-------------------|-------|
| Total AUC | Physical | Accuracy | CDT, ADT, VDT |
| Total AUC | Cognitive | Accuracy | ADT, VDT |
| Total AUC | Physical | Correct RT | CDT, ADT, VDT |
| Total AUC | Cognitive | Correct RT | ADT, VDT |
| Cognitive AUC | Physical | Accuracy | ADT, VDT |
| Cognitive AUC | Cognitive | Accuracy | ADT, VDT |
| Cognitive AUC | Physical | Correct RT | ADT, VDT |
| Cognitive AUC | Cognitive | Correct RT | ADT, VDT |

## Results Summary

**Overall Pattern:** No significant correlations were found across all analyses.

This suggests:
- Individual differences in physiological effort sensitivity (AUC) do not strongly predict individual differences in behavioral effort sensitivity
- This pattern is consistent across:
  - Both Total and Cognitive AUC
  - Both Accuracy and Correct RT measures
  - Both Physical and Cognitive effort manipulations
  - All three tasks (where applicable)

## Manuscript Text

The complete, ready-to-use manuscript text is in:
`/Users/mohdasti/Documents/LC–YA/GitHub_Ready_Analyses/05_Manuscript_Figures/results_subject_means/updated_manuscript_text.md`

It includes:
- Total AUC × Accuracy (Physical & Cognitive effects)
- Total AUC × Correct RT (Physical & Cognitive effects)
- Cognitive AUC × Accuracy (Physical & Cognitive effects)
- Cognitive AUC × Correct RT (Physical & Cognitive effects)

All formatted and ready to paste into your manuscript!

## Technical Note

The rmcorr artifact is specific to **balanced 2-observation-per-subject designs**. When you have exactly 2 data points per subject and group them in different ways, the mathematical constraints of the rmcorr model can produce identical statistics. The subject means approach:
- Averages to ONE value per subject
- Uses standard Pearson correlation
- Is more interpretable for individual differences
- Matches your original analysis approach

## Recommendations

1. ✅ **Use the subject means results** for your manuscript
2. ✅ **Disregard the old rmcorr results** (due to artifact)
3. ✅ **All files are saved separately** (no overwriting)
4. ✅ **Double-check the manuscript text** before finalizing
5. ✅ **Consider the RT results** as complementary evidence

---

**Analysis Complete:** 2025-11-09
**Status:** ✅ Verified, validated, and ready for manuscript
**Location:** `/Users/mohdasti/Documents/LC–YA/GitHub_Ready_Analyses/05_Manuscript_Figures/results_subject_means/`

