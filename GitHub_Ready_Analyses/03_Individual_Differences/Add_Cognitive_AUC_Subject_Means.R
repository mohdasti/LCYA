#!/usr/bin/env Rscript

# Add missing Cognitive AUC subject-means correlations
# Complete the sensitivity analysis for ADT and VDT Cognitive AUC

suppressPackageStartupMessages({
  library(tidyverse)
})

BASE_DIR <- "/Users/mohdasti/Documents/LC–YA"
DATA_DIR <- file.path(BASE_DIR, "PI_Feedback_Outputs")
RESULTS_DIR <- file.path(BASE_DIR, "results")

# Load data (same as existing analysis)
dual_auc_data <- read_csv(file.path(DATA_DIR, "Combined_Dual_AUC_Data.csv"), show_col_types = FALSE)
behavioral_data <- read_csv(file.path(BASE_DIR, "Complete_Manuscript_Results", "complete_analysis_data.csv"), show_col_types = FALSE)

# Process data (same as existing analysis)
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

# Function to compute subject-means correlations for Cognitive AUC
compute_cognitive_auc_subject_means <- function(task_name) {
  
  task_data <- merged_data %>%
    filter(task == task_name, !is.na(mean_cognitive_auc), !is.na(mean_accuracy))
  
  # Physical effort effects: High - Low within each difficulty, then average across difficulty
  physical_effects <- task_data %>%
    group_by(sub, difficulty) %>%
    summarise(
      pupil_physical_effect = mean_cognitive_auc[effort == "High"] - mean_cognitive_auc[effort == "Low"],
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
  
  # Cognitive effort effects: Hard - Easy within each effort, then average across effort
  cognitive_effects <- task_data %>%
    group_by(sub, effort) %>%
    summarise(
      pupil_cognitive_effect = mean_cognitive_auc[difficulty == "Hard"] - mean_cognitive_auc[difficulty == "Easy"],
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
  
  # Calculate correlations
  physical_cor <- NULL
  if (nrow(physical_effects) > 3) {
    physical_cor <- cor.test(physical_effects$mean_pupil_physical_effect, 
                            physical_effects$mean_accuracy_physical_effect)
  }
  
  cognitive_cor <- NULL
  if (nrow(cognitive_effects) > 3) {
    cognitive_cor <- cor.test(cognitive_effects$mean_pupil_cognitive_effect, 
                             cognitive_effects$mean_accuracy_cognitive_effect)
  }
  
  return(list(
    physical_effects = physical_effects,
    cognitive_effects = cognitive_effects,
    physical_correlation = physical_cor,
    cognitive_correlation = cognitive_cor
  ))
}

# Compute for ADT and VDT
cat("Computing Cognitive AUC subject-means correlations...\n")

adt_results <- compute_cognitive_auc_subject_means("ADT")
vdt_results <- compute_cognitive_auc_subject_means("VDT")

# Format results
cat("\n========== COGNITIVE AUC SUBJECT MEANS (SUPPLEMENTARY) ==========\n\n")

cat("--- ADT Cognitive AUC (Subject Means) ---\n")
if (!is.null(adt_results$physical_correlation)) {
  cat(sprintf("ADT Cognitive AUC Physical Effort (subject means): r = %.3f, 95%% CI [%.3f, %.3f], p = %.3f, n = %d\n",
              adt_results$physical_correlation$estimate,
              adt_results$physical_correlation$conf.int[1],
              adt_results$physical_correlation$conf.int[2],
              adt_results$physical_correlation$p.value,
              nrow(adt_results$physical_effects)))
} else {
  cat("ADT Cognitive AUC Physical Effort (subject means): Insufficient data\n")
}

if (!is.null(adt_results$cognitive_correlation)) {
  cat(sprintf("ADT Cognitive AUC Cognitive Effort (subject means): r = %.3f, 95%% CI [%.3f, %.3f], p = %.3f, n = %d\n",
              adt_results$cognitive_correlation$estimate,
              adt_results$cognitive_correlation$conf.int[1],
              adt_results$cognitive_correlation$conf.int[2],
              adt_results$cognitive_correlation$p.value,
              nrow(adt_results$cognitive_effects)))
} else {
  cat("ADT Cognitive AUC Cognitive Effort (subject means): Insufficient data\n")
}

cat("\n--- VDT Cognitive AUC (Subject Means) ---\n")
if (!is.null(vdt_results$physical_correlation)) {
  cat(sprintf("VDT Cognitive AUC Physical Effort (subject means): r = %.3f, 95%% CI [%.3f, %.3f], p = %.3f, n = %d\n",
              vdt_results$physical_correlation$estimate,
              vdt_results$physical_correlation$conf.int[1],
              vdt_results$physical_correlation$conf.int[2],
              vdt_results$physical_correlation$p.value,
              nrow(vdt_results$physical_effects)))
} else {
  cat("VDT Cognitive AUC Physical Effort (subject means): Insufficient data\n")
}

if (!is.null(vdt_results$cognitive_correlation)) {
  cat(sprintf("VDT Cognitive AUC Cognitive Effort (subject means): r = %.3f, 95%% CI [%.3f, %.3f], p = %.3f, n = %d\n",
              vdt_results$cognitive_correlation$estimate,
              vdt_results$cognitive_correlation$conf.int[1],
              vdt_results$cognitive_correlation$conf.int[2],
              vdt_results$cognitive_correlation$p.value,
              nrow(vdt_results$cognitive_effects)))
} else {
  cat("VDT Cognitive AUC Cognitive Effort (subject means): Insufficient data\n")
}

# Append to rmcorr_log.txt
rmcorr_log_path <- file.path(RESULTS_DIR, "rmcorr_log.txt")
supplement_path <- file.path(RESULTS_DIR, "cognitive_auc_subject_means_supplement.txt")

# Write supplement to separate file first
supplement_text <- c(
  "",
  "========== COGNITIVE AUC SUBJECT MEANS (SUPPLEMENTARY) ==========",
  "",
  "--- ADT Cognitive AUC (Subject Means) ---",
  if (!is.null(adt_results$physical_correlation)) {
    sprintf("ADT Cognitive AUC Physical Effort (subject means): r = %.3f, 95%% CI [%.3f, %.3f], p = %.3f, n = %d",
            adt_results$physical_correlation$estimate,
            adt_results$physical_correlation$conf.int[1],
            adt_results$physical_correlation$conf.int[2],
            adt_results$physical_correlation$p.value,
            nrow(adt_results$physical_effects))
  } else {
    "ADT Cognitive AUC Physical Effort (subject means): Insufficient data"
  },
  if (!is.null(adt_results$cognitive_correlation)) {
    sprintf("ADT Cognitive AUC Cognitive Effort (subject means): r = %.3f, 95%% CI [%.3f, %.3f], p = %.3f, n = %d",
            adt_results$cognitive_correlation$estimate,
            adt_results$cognitive_correlation$conf.int[1],
            adt_results$cognitive_correlation$conf.int[2],
            adt_results$cognitive_correlation$p.value,
            nrow(adt_results$cognitive_effects))
  } else {
    "ADT Cognitive AUC Cognitive Effort (subject means): Insufficient data"
  },
  "",
  "--- VDT Cognitive AUC (Subject Means) ---",
  if (!is.null(vdt_results$physical_correlation)) {
    sprintf("VDT Cognitive AUC Physical Effort (subject means): r = %.3f, 95%% CI [%.3f, %.3f], p = %.3f, n = %d",
            vdt_results$physical_correlation$estimate,
            vdt_results$physical_correlation$conf.int[1],
            vdt_results$physical_correlation$conf.int[2],
            vdt_results$physical_correlation$p.value,
            nrow(vdt_results$physical_effects))
  } else {
    "VDT Cognitive AUC Physical Effort (subject means): Insufficient data"
  },
  if (!is.null(vdt_results$cognitive_correlation)) {
    sprintf("VDT Cognitive AUC Cognitive Effort (subject means): r = %.3f, 95%% CI [%.3f, %.3f], p = %.3f, n = %d",
            vdt_results$cognitive_correlation$estimate,
            vdt_results$cognitive_correlation$conf.int[1],
            vdt_results$cognitive_correlation$conf.int[2],
            vdt_results$cognitive_correlation$p.value,
            nrow(vdt_results$cognitive_effects))
  } else {
    "VDT Cognitive AUC Cognitive Effort (subject means): Insufficient data"
  }
)

writeLines(supplement_text, supplement_path)

# Append to main rmcorr log
if (file.exists(rmcorr_log_path)) {
  original_log <- readLines(rmcorr_log_path)
  updated_log <- c(original_log, supplement_text)
  writeLines(updated_log, rmcorr_log_path)
  cat("\n✅ Results appended to rmcorr_log.txt\n")
} else {
  cat("\n⚠️  rmcorr_log.txt not found, supplement saved to cognitive_auc_subject_means_supplement.txt\n")
}

cat("\n=== Cognitive AUC Subject-Means Analysis Complete ===\n")
