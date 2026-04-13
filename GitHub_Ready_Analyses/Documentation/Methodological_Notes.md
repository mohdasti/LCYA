# Methodological Notes

## Statistical Approach

### Pupil Waveform Analysis
- **Baseline Correction**: 500ms pre-squeeze window (-0.5s to 0s) chosen after comparison with 750ms and 1000ms baselines
- **Separation Metric**: Zero separation between Hard/Easy conditions before stimulus onset confirms proper baseline correction
- **Smoothing**: GAM trajectories with 95% confidence intervals using mgcv package
- **Time-locking**: All analyses time-locked to squeeze onset (0s) with extended range (-1.0s to response onset)

### AUC Measures
- **Total AUC**: Calculated on raw pupil data from squeeze onset to response onset
- **Cognitive AUC**: Calculated on re-baselined data (B2b) from 300ms after target stimulus to response onset
- **Rationale**: Total AUC captures overall trial arousal; Cognitive AUC isolates decision-phase response

### Individual Differences Analysis
- **Primary Method**: Multivariate Bayesian mixed-effects models (brms)
- **Target Estimand**: Correlation between subject-specific effort slopes across physiological and behavioral outcomes
- **Rationale**: Avoids statistical artifacts of difference-score correlations while directly estimating the association of interest
- **Sensitivity Analyses**: rmcorr and subject-means correlations for robustness

## Key Methodological Decisions

### 1. Baseline Period Selection
**Decision**: 500ms baseline (-0.5s to 0s)
**Rationale**: 
- Comparison with 750ms and 1000ms baselines showed identical separation metrics (all achieved zero separation)
- 500ms provides sufficient data for stable baseline estimation
- Consistent with pupillometry best practices

### 2. Cognitive AUC vs Total AUC for Cognitive Effort
**Decision**: Use Cognitive AUC for cognitive effort effects, Total AUC for physical effort effects
**Rationale**:
- Cognitive AUC is specifically designed to isolate decision-phase arousal
- Total AUC includes anticipatory, motor, and tonic components that are not relevant to cognitive processing
- This alignment maximizes construct validity

### 3. CDT Analysis Limitations
**Decision**: CDT cognitive effort effects excluded from primary analyses
**Rationale**:
- CDT cognitive difficulty is confounded with physical effort due to task design
- Cognitive AUC for CDT is not interpretable as a pure cognitive measure
- Physical effort effects remain valid and are included

### 4. Bayesian vs Frequentist Approach
**Decision**: Bayesian primary analysis with frequentist sensitivity
**Rationale**:
- Bayesian approach provides proper uncertainty quantification
- Avoids p-value correction issues with multiple comparisons
- Credible intervals are more interpretable than confidence intervals
- Sensitivity analyses confirm robustness across methods

## Statistical Models

### Pupil Waveform Models
```r
# GAM smoothing for waveforms
gam(pupil_isolated ~ s(time_from_squeeze, by = condition, k = 20) + 
    s(sub, bs = "re"), 
    data = pupil_data, method = "REML")
```

### AUC Linear Mixed Models
```r
# Total AUC models
lmer(mean_Total_AUC ~ difficulty * effort + (1|sub), data = task_data)

# Cognitive AUC models (ADT/VDT only)
lmer(mean_Cognitive_AUC ~ difficulty * effort + (1|sub), data = task_data)

# CDT Total AUC (physical effort only)
lmer(mean_Total_AUC ~ effort + (1|sub), data = cdt_data)
```

### Individual Differences Models
```r
# Bivariate Bayesian model
bf_auc <- bf(auc_value ~ 1 + effort_contrast + difficulty_contrast + 
             effort_contrast:difficulty_contrast + (1 + effort_contrast | p | sub))
bf_acc <- bf(acc_value ~ 1 + effort_contrast + difficulty_contrast + 
             effort_contrast:difficulty_contrast + (1 + effort_contrast | p | sub))

brm(bf_auc + bf_acc + set_rescor(FALSE), data = wide_data, 
    family = gaussian(), prior = priors)
```

## Quality Control Measures

### Data Preprocessing
- **Missing Data**: Listwise deletion for incomplete cases
- **Outliers**: Visual inspection of waveforms and AUC distributions
- **Data Integrity**: Cross-validation between AUC and behavioral datasets

### Model Diagnostics
- **Convergence**: R̂ < 1.01 for all parameters
- **Effective Sample Size**: ESS > 400 for all parameters
- **Divergences**: <1% of post-warmup draws
- **Posterior Predictive Checks**: Visual inspection of model fit

### Sensitivity Analyses
- **Baseline Periods**: Tested 500ms, 750ms, and 1000ms baselines
- **Correlation Methods**: Compared Bayesian, rmcorr, and subject-means approaches
- **Model Specifications**: Tested different random-effects structures

## Limitations and Considerations

### Sample Size
- **N=39**: Provides adequate power for main effects but limited precision for individual differences
- **Individual Differences**: Wide credible intervals reflect uncertainty; larger samples needed for precise correlation estimates

### Measurement Reliability
- **Difference Scores**: May have reduced reliability compared to condition-level measures
- **Effort Effects**: Reliability depends on within-subject stability across conditions
- **Mitigation**: Multiple analytical approaches provide robustness checks

### Task-Specific Considerations
- **CDT**: Cognitive difficulty confounded with physical effort
- **ADT/VDT**: Clean separation of cognitive and physical effort manipulations
- **Cross-Task Consistency**: Moderate correlations suggest some generalizability

### Statistical Assumptions
- **Normality**: Residuals approximately normal for all models
- **Independence**: Properly modeled with random effects structure
- **Linearity**: GAM smoothing accommodates non-linear relationships

## Reproducibility Measures

### Code Organization
- **Modular Structure**: Separate scripts for each analysis component
- **Clear Documentation**: Extensive comments and README files
- **Version Control**: All scripts saved with timestamps

### Data Management
- **Relative Paths**: All file paths relative to project root
- **Data Validation**: Checks for file existence and data integrity
- **Output Organization**: Systematic file naming and directory structure

### Computational Reproducibility
- **Fixed Seeds**: All random processes use fixed seeds
- **Package Versions**: Documented R package versions
- **System Information**: R version and system details recorded

## Future Improvements

### Methodological Enhancements
- **Hierarchical Models**: Pool information across tasks for improved precision
- **Measurement Error**: Explicit modeling of measurement uncertainty
- **Non-linear Effects**: More sophisticated modeling of time-course effects

### Statistical Power
- **Larger Samples**: Increase N for more precise individual differences estimates
- **Longitudinal Design**: Multiple sessions to improve reliability
- **Cross-Validation**: Out-of-sample validation of individual differences

### Computational Efficiency
- **Parallel Processing**: Optimize MCMC sampling
- **Approximate Methods**: Consider variational inference for large datasets
- **Cloud Computing**: Scale to larger datasets

## References

### Key Methodological Papers
- Bakdash & Marusich (2017): Repeated measures correlation
- Bürkner (2017): brms package for Bayesian modeling
- Mathôt et al. (2022): Pupillometry methodology review
- Zénon et al. (2014): Effort and pupillometry

### Statistical Methods
- Gelman & Hill (2007): Data Analysis Using Regression and Multilevel/Hierarchical Models
- McElreath (2020): Statistical Rethinking
- Vehtari et al. (2021): Bayesian workflow

### Software Documentation
- brms: https://paul-buerkner.github.io/brms/
- mgcv: https://cran.r-project.org/web/packages/mgcv/
- rmcorr: https://cran.r-project.org/web/packages/rmcorr/













