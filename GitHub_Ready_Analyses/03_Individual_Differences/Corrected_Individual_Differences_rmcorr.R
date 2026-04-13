#!/usr/bin/env Rscript

# Corrected Individual Differences Analysis using rmcorr
# Based on literature review recommendations
# Addresses non-independence of observations within subjects

suppressPackageStartupMessages({
  library(tidyverse)
  library(rmcorr)
})

# Set up directories
BASE_DIR <- "/Users/mohdasti/Documents/LC–YA"
DATA_DIR <- file.path(BASE_DIR, "PI_Feedback_Outputs")
RESULTS_DIR <- file.path(BASE_DIR, "Corrected_rmcorr_Individual_Differences_Results")

if (!dir.exists(RESULTS_DIR)) {
  dir.create(RESULTS_DIR, recursive = TRUE)
}

cat("=== CORRECTED INDIVIDUAL DIFFERENCES ANALYSIS (rmcorr) ===\n")
cat("Analysis Date:", Sys.time(), "\n")
cat("Using repeated measures correlation to address non-independence\n")
cat("Per literature review recommendations\n\n")

# Load data
dual_auc_data <- read_csv(file.path(DATA_DIR, "Combined_Dual_AUC_Data.csv"), show_col_types = FALSE)
behavioral_data <- read_csv(file.path(BASE_DIR, "Complete_Manuscript_Results", "complete_analysis_data.csv"), show_col_types = FALSE)

# Process data
processed_data <- dual_auc_data %>%
  mutate(
    sub = as.numeric(sub),
    difficulty = str_extract(condition, "^[^/]+") %>% str_trim(),
    effort = str_extract(condition, "[^/]+$") %>% str_trim(),
    task = factor(task, levels = c("CDT", "ADT", "VDT")),
    mean_total_auc = mean_physical_auc,
    mean_cognitive_auc = mean_cognitive_auc
  )

behavioral_summary <- behavioral_data %>%
  filter(!is.na(accuracy)) %>%
  group_by(sub, task, difficulty, effort) %>%
  summarise(
    mean_accuracy = mean(accuracy, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  mutate(
    sub = as.numeric(str_remove(sub, "S")),
    difficulty = factor(difficulty, levels = c("Easy", "Hard")),
    effort = factor(effort, levels = c("Low", "High")),
    task = factor(task, levels = c("CDT", "ADT", "VDT"))
  )

merged_data <- processed_data %>%
  left_join(behavioral_summary, by = c("sub", "task", "difficulty", "effort"))

cat("Data loaded and processed successfully\n\n")

# Function to calculate individual differences using rmcorr
calculate_rmcorr_individual_differences <- function(task_data, task_name, measure_name, measure_var, include_cognitive = TRUE) {
  
  # Calculate individual subject means for each condition
  individual_means <- task_data %>%
    filter(!is.na(!!sym(measure_var)), !is.na(mean_accuracy)) %>%
    group_by(sub, difficulty, effort) %>%
    summarise(
      mean_measure = mean(!!sym(measure_var), na.rm = TRUE),
      mean_accuracy = mean(mean_accuracy, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Calculate physical effort effects (High - Low) for each subject and difficulty
  physical_effects <- individual_means %>%
    group_by(sub, difficulty) %>%
    summarise(
      pupil_physical_effect = mean_measure[effort == "High"] - mean_measure[effort == "Low"],
      accuracy_physical_effect = mean_accuracy[effort == "High"] - mean_accuracy[effort == "Low"],
      .groups = "drop"
    ) %>%
    filter(!is.na(pupil_physical_effect), !is.na(accuracy_physical_effect))
  
  # Calculate cognitive effort effects (Hard - Easy) for each subject and effort level
  if (include_cognitive) {
    cognitive_effects <- individual_means %>%
      group_by(sub, effort) %>%
      summarise(
        pupil_cognitive_effect = mean_measure[difficulty == "Hard"] - mean_measure[difficulty == "Easy"],
        accuracy_cognitive_effect = mean_accuracy[difficulty == "Hard"] - mean_accuracy[difficulty == "Easy"],
        .groups = "drop"
      ) %>%
      filter(!is.na(pupil_cognitive_effect), !is.na(accuracy_cognitive_effect))
  } else {
    cognitive_effects <- data.frame(
      sub = numeric(0),
      effort = character(0),
      pupil_cognitive_effect = numeric(0),
      accuracy_cognitive_effect = numeric(0)
    )
  }
  
  # Calculate rmcorr for physical effort effects
  physical_rmcorr <- NULL
  if (nrow(physical_effects) > 3) {
    tryCatch({
      physical_rmcorr <- rmcorr(participant = sub,
                               measure1 = pupil_physical_effect,
                               measure2 = accuracy_physical_effect,
                               dataset = physical_effects)
      
      cat(sprintf("%s %s Physical Effort (rmcorr): r_rm = %.3f, 95%% CI [%.3f, %.3f], p = %s, df = %d, n = %d\n",
                  task_name, measure_name,
                  physical_rmcorr$r, 
                  physical_rmcorr$CI[1], physical_rmcorr$CI[2],
                  format.pval(physical_rmcorr$p, digits = 3),
                  physical_rmcorr$df,
                  nrow(physical_effects)))
    }, error = function(e) {
      cat(sprintf("%s %s Physical Effort: rmcorr failed - %s\n", task_name, measure_name, e$message))
    })
  }
  
  # Calculate rmcorr for cognitive effort effects
  cognitive_rmcorr <- NULL
  if (include_cognitive && nrow(cognitive_effects) > 3) {
    tryCatch({
      cognitive_rmcorr <- rmcorr(participant = sub,
                                measure1 = pupil_cognitive_effect,
                                measure2 = accuracy_cognitive_effect,
                                dataset = cognitive_effects)
      
      cat(sprintf("%s %s Cognitive Effort (rmcorr): r_rm = %.3f, 95%% CI [%.3f, %.3f], p = %s, df = %d, n = %d\n",
                  task_name, measure_name,
                  cognitive_rmcorr$r, 
                  cognitive_rmcorr$CI[1], cognitive_rmcorr$CI[2],
                  format.pval(cognitive_rmcorr$p, digits = 3),
                  cognitive_rmcorr$df,
                  nrow(cognitive_effects)))
    }, error = function(e) {
      cat(sprintf("%s %s Cognitive Effort: rmcorr failed - %s\n", task_name, measure_name, e$message))
    })
  } else if (!include_cognitive) {
    cat(sprintf("%s %s Cognitive Effort: Skipped per Lani's recommendations\n", task_name, measure_name))
  }
  
  return(list(
    physical_effects = physical_effects,
    cognitive_effects = cognitive_effects,
    physical_rmcorr = physical_rmcorr,
    cognitive_rmcorr = cognitive_rmcorr
  ))
}

# Calculate individual differences for each task
cat("========== TOTAL AUC ANALYSIS (rmcorr) ==========\n\n")

# CDT: Physical effort only
cat("--- CDT Total AUC ---\n")
cdt_total <- calculate_rmcorr_individual_differences(
  merged_data %>% filter(task == "CDT"),
  "CDT", "Total AUC", "mean_total_auc", include_cognitive = FALSE
)

# ADT: Full analysis
cat("\n--- ADT Total AUC ---\n")
adt_total <- calculate_rmcorr_individual_differences(
  merged_data %>% filter(task == "ADT"),
  "ADT", "Total AUC", "mean_total_auc", include_cognitive = TRUE
)

# VDT: Full analysis
cat("\n--- VDT Total AUC ---\n")
vdt_total <- calculate_rmcorr_individual_differences(
  merged_data %>% filter(task == "VDT"),
  "VDT", "Total AUC", "mean_total_auc", include_cognitive = TRUE
)

cat("\n========== COGNITIVE AUC ANALYSIS (rmcorr) ==========\n\n")

cat("CDT Cognitive AUC: Skipped per Lani's recommendations\n\n")

# ADT: Full analysis
cat("--- ADT Cognitive AUC ---\n")
adt_cognitive <- calculate_rmcorr_individual_differences(
  merged_data %>% filter(task == "ADT"),
  "ADT", "Cognitive AUC", "mean_cognitive_auc", include_cognitive = TRUE
)

# VDT: Full analysis
cat("\n--- VDT Cognitive AUC ---\n")
vdt_cognitive <- calculate_rmcorr_individual_differences(
  merged_data %>% filter(task == "VDT"),
  "VDT", "Cognitive AUC", "mean_cognitive_auc", include_cognitive = TRUE
)

# Sensitivity analysis: Subject means approach
cat("\n========== SENSITIVITY ANALYSIS: SUBJECT MEANS ==========\n\n")

calculate_subject_means_correlation <- function(task_data, task_name, measure_name, measure_var, include_cognitive = TRUE) {
  
  individual_means <- task_data %>%
    filter(!is.na(!!sym(measure_var)), !is.na(mean_accuracy)) %>%
    group_by(sub, difficulty, effort) %>%
    summarise(
      mean_measure = mean(!!sym(measure_var), na.rm = TRUE),
      mean_accuracy = mean(mean_accuracy, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Calculate physical effort effects and average across difficulty
  physical_effects <- individual_means %>%
    group_by(sub, difficulty) %>%
    summarise(
      pupil_physical_effect = mean_measure[effort == "High"] - mean_measure[effort == "Low"],
      accuracy_physical_effect = mean_accuracy[effort == "High"] - mean_accuracy[effort == "Low"],
      .groups = "drop"
    ) %>%
    group_by(sub) %>%
    summarise(
      mean_pupil_physical_effect = mean(pupil_physical_effect, na.rm = TRUE),
      mean_accuracy_physical_effect = mean(accuracy_physical_effect, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    filter(!is.na(mean_pupil_physical_effect), !is.na(mean_accuracy_physical_effect))
  
  # Calculate cognitive effort effects and average across effort
  if (include_cognitive) {
    cognitive_effects <- individual_means %>%
      group_by(sub, effort) %>%
      summarise(
        pupil_cognitive_effect = mean_measure[difficulty == "Hard"] - mean_measure[difficulty == "Easy"],
        accuracy_cognitive_effect = mean_accuracy[difficulty == "Hard"] - mean_accuracy[difficulty == "Easy"],
        .groups = "drop"
      ) %>%
      group_by(sub) %>%
      summarise(
        mean_pupil_cognitive_effect = mean(pupil_cognitive_effect, na.rm = TRUE),
        mean_accuracy_cognitive_effect = mean(accuracy_cognitive_effect, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      filter(!is.na(mean_pupil_cognitive_effect), !is.na(mean_accuracy_cognitive_effect))
  } else {
    cognitive_effects <- data.frame(
      sub = numeric(0),
      mean_pupil_cognitive_effect = numeric(0),
      mean_accuracy_cognitive_effect = numeric(0)
    )
  }
  
  # Calculate correlations
  physical_cor <- NULL
  if (nrow(physical_effects) > 3) {
    physical_cor <- cor.test(physical_effects$mean_pupil_physical_effect, 
                            physical_effects$mean_accuracy_physical_effect)
    cat(sprintf("%s %s Physical Effort (subject means): r = %.3f, 95%% CI [%.3f, %.3f], p = %s, n = %d\n",
                task_name, measure_name,
                physical_cor$estimate,
                physical_cor$conf.int[1], physical_cor$conf.int[2],
                format.pval(physical_cor$p.value, digits = 3),
                nrow(physical_effects)))
  }
  
  cognitive_cor <- NULL
  if (include_cognitive && nrow(cognitive_effects) > 3) {
    cognitive_cor <- cor.test(cognitive_effects$mean_pupil_cognitive_effect, 
                             cognitive_effects$mean_accuracy_cognitive_effect)
    cat(sprintf("%s %s Cognitive Effort (subject means): r = %.3f, 95%% CI [%.3f, %.3f], p = %s, n = %d\n",
                task_name, measure_name,
                cognitive_cor$estimate,
                cognitive_cor$conf.int[1], cognitive_cor$conf.int[2],
                format.pval(cognitive_cor$p.value, digits = 3),
                nrow(cognitive_effects)))
  }
  
  return(list(
    physical_effects = physical_effects,
    cognitive_effects = cognitive_effects,
    physical_correlation = physical_cor,
    cognitive_correlation = cognitive_cor
  ))
}

# Sensitivity analysis for Total AUC
cat("--- CDT Total AUC (Subject Means) ---\n")
cdt_total_sensitivity <- calculate_subject_means_correlation(
  merged_data %>% filter(task == "CDT"),
  "CDT", "Total AUC", "mean_total_auc", include_cognitive = FALSE
)

cat("\n--- ADT Total AUC (Subject Means) ---\n")
adt_total_sensitivity <- calculate_subject_means_correlation(
  merged_data %>% filter(task == "ADT"),
  "ADT", "Total AUC", "mean_total_auc", include_cognitive = TRUE
)

cat("\n--- VDT Total AUC (Subject Means) ---\n")
vdt_total_sensitivity <- calculate_subject_means_correlation(
  merged_data %>% filter(task == "VDT"),
  "VDT", "Total AUC", "mean_total_auc", include_cognitive = TRUE
)

# Save results
write_csv(cdt_total$physical_effects, file.path(RESULTS_DIR, "cdt_total_auc_physical_effects_rmcorr.csv"))
write_csv(adt_total$physical_effects, file.path(RESULTS_DIR, "adt_total_auc_physical_effects_rmcorr.csv"))
write_csv(adt_total$cognitive_effects, file.path(RESULTS_DIR, "adt_total_auc_cognitive_effects_rmcorr.csv"))
write_csv(vdt_total$physical_effects, file.path(RESULTS_DIR, "vdt_total_auc_physical_effects_rmcorr.csv"))
write_csv(vdt_total$cognitive_effects, file.path(RESULTS_DIR, "vdt_total_auc_cognitive_effects_rmcorr.csv"))

write_csv(adt_cognitive$physical_effects, file.path(RESULTS_DIR, "adt_cognitive_auc_physical_effects_rmcorr.csv"))
write_csv(adt_cognitive$cognitive_effects, file.path(RESULTS_DIR, "adt_cognitive_auc_cognitive_effects_rmcorr.csv"))
write_csv(vdt_cognitive$physical_effects, file.path(RESULTS_DIR, "vdt_cognitive_auc_physical_effects_rmcorr.csv"))
write_csv(vdt_cognitive$cognitive_effects, file.path(RESULTS_DIR, "vdt_cognitive_auc_cognitive_effects_rmcorr.csv"))

# Save sensitivity analysis results
write_csv(cdt_total_sensitivity$physical_effects, file.path(RESULTS_DIR, "cdt_total_auc_physical_effects_subject_means.csv"))
write_csv(adt_total_sensitivity$physical_effects, file.path(RESULTS_DIR, "adt_total_auc_physical_effects_subject_means.csv"))
write_csv(adt_total_sensitivity$cognitive_effects, file.path(RESULTS_DIR, "adt_total_auc_cognitive_effects_subject_means.csv"))
write_csv(vdt_total_sensitivity$physical_effects, file.path(RESULTS_DIR, "vdt_total_auc_physical_effects_subject_means.csv"))
write_csv(vdt_total_sensitivity$cognitive_effects, file.path(RESULTS_DIR, "vdt_total_auc_cognitive_effects_subject_means.csv"))

cat("\n=== CORRECTED INDIVIDUAL DIFFERENCES ANALYSIS COMPLETE ===\n")
cat("Results saved to:", RESULTS_DIR, "\n")
cat("\n📊 Key Changes:\n")
cat("✅ Using rmcorr to address non-independence\n")
cat("✅ Proper degrees of freedom (df = n-1, not 2n-2)\n")
cat("✅ Sensitivity analysis with subject means approach\n")
cat("✅ Statistically valid approach per literature review\n")
cat("✅ Maintains all data while addressing independence assumption\n")

