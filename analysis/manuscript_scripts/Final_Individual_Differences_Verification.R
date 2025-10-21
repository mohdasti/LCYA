#!/usr/bin/env Rscript

# Final Individual Differences Analysis Verification
# Using current protocol: Total AUC (all tasks) + Cognitive AUC (ADT/VDT only)
# Per Lani's recommendations: CDT uses physical effort only, no cognitive effects

suppressPackageStartupMessages({
  library(tidyverse)
})

BASE_DIR <- "/Users/mohdasti/Documents/LC–YA"
DATA_DIR <- file.path(BASE_DIR, "PI_Feedback_Outputs")
RESULTS_DIR <- file.path(BASE_DIR, "Final_Individual_Differences_Results")

if (!dir.exists(RESULTS_DIR)) {
  dir.create(RESULTS_DIR, recursive = TRUE)
}

cat("=== FINAL INDIVIDUAL DIFFERENCES ANALYSIS ===\n")
cat("Analysis Date:", Sys.time(), "\n")
cat("Protocol: Total AUC (all tasks) + Cognitive AUC (ADT/VDT only)\n")
cat("Per Lani's recommendations: CDT physical effort only\n\n")

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
    mean_total_auc = mean_physical_auc,  # Total AUC from squeeze to response
    mean_cognitive_auc = mean_cognitive_auc  # Cognitive AUC from 300ms post-stimulus to response
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

cat("Data loaded and merged successfully\n\n")

# Function following original method (separate by difficulty, creates 2 points per subject)
calculate_individual_differences <- function(task_data, task_name, measure_name, measure_var, include_cognitive = TRUE) {
  
  individual_means <- task_data %>%
    filter(!is.na(!!sym(measure_var)), !is.na(mean_accuracy)) %>%
    group_by(sub, difficulty, effort) %>%
    summarise(
      mean_measure = mean(!!sym(measure_var), na.rm = TRUE),
      mean_accuracy = mean(mean_accuracy, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Physical effort effects (High - Low) calculated separately for each difficulty
  physical_effects <- individual_means %>%
    group_by(sub, difficulty) %>%
    summarise(
      pupil_physical_effect = mean_measure[effort == "High"] - mean_measure[effort == "Low"],
      accuracy_physical_effect = mean_accuracy[effort == "High"] - mean_accuracy[effort == "Low"],
      .groups = "drop"
    ) %>%
    filter(!is.na(pupil_physical_effect), !is.na(accuracy_physical_effect))
  
  # Cognitive effort effects (Hard - Easy) calculated separately for each effort level
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
  
  # Correlations for physical effort
  physical_cor <- NULL
  if (nrow(physical_effects) > 3) {
    physical_cor <- cor.test(physical_effects$pupil_physical_effect, physical_effects$accuracy_physical_effect)
    cat(sprintf("%s %s Physical Effort: r = %.3f, p = %s, 95%% CI [%.3f, %.3f], n = %d\n",
                task_name, measure_name,
                physical_cor$estimate,
                format.pval(physical_cor$p.value, digits = 3),
                physical_cor$conf.int[1],
                physical_cor$conf.int[2],
                nrow(physical_effects)))
  }
  
  # Correlations for cognitive effort
  cognitive_cor <- NULL
  if (include_cognitive && nrow(cognitive_effects) > 3) {
    cognitive_cor <- cor.test(cognitive_effects$pupil_cognitive_effect, cognitive_effects$accuracy_cognitive_effect)
    cat(sprintf("%s %s Cognitive Effort: r = %.3f, p = %s, 95%% CI [%.3f, %.3f], n = %d\n",
                task_name, measure_name,
                cognitive_cor$estimate,
                format.pval(cognitive_cor$p.value, digits = 3),
                cognitive_cor$conf.int[1],
                cognitive_cor$conf.int[2],
                nrow(cognitive_effects)))
  } else if (!include_cognitive) {
    cat(sprintf("%s %s Cognitive Effort: Skipped per Lani's recommendations\n", task_name, measure_name))
  }
  
  return(list(
    physical_effects = physical_effects,
    cognitive_effects = cognitive_effects,
    physical_correlation = physical_cor,
    cognitive_correlation = cognitive_cor
  ))
}

cat("========== TOTAL AUC INDIVIDUAL DIFFERENCES ==========\n\n")

# CDT: Physical effort only
cat("--- CDT Total AUC ---\n")
cdt_total <- calculate_individual_differences(
  merged_data %>% filter(task == "CDT"),
  "CDT", "Total AUC", "mean_total_auc", include_cognitive = FALSE
)

# ADT: Full analysis
cat("\n--- ADT Total AUC ---\n")
adt_total <- calculate_individual_differences(
  merged_data %>% filter(task == "ADT"),
  "ADT", "Total AUC", "mean_total_auc", include_cognitive = TRUE
)

# VDT: Full analysis
cat("\n--- VDT Total AUC ---\n")
vdt_total <- calculate_individual_differences(
  merged_data %>% filter(task == "VDT"),
  "VDT", "Total AUC", "mean_total_auc", include_cognitive = TRUE
)

cat("\n========== COGNITIVE AUC INDIVIDUAL DIFFERENCES ==========\n\n")

cat("CDT Cognitive AUC: Skipped per Lani's recommendations (cognitive effects uninterpretable)\n\n")

# ADT: Full analysis
cat("--- ADT Cognitive AUC ---\n")
adt_cognitive <- calculate_individual_differences(
  merged_data %>% filter(task == "ADT"),
  "ADT", "Cognitive AUC", "mean_cognitive_auc", include_cognitive = TRUE
)

# VDT: Full analysis
cat("\n--- VDT Cognitive AUC ---\n")
vdt_cognitive <- calculate_individual_differences(
  merged_data %>% filter(task == "VDT"),
  "VDT", "Cognitive AUC", "mean_cognitive_auc", include_cognitive = TRUE
)

# Cross-task consistency analysis
cat("\n========== CROSS-TASK CONSISTENCY ANALYSIS ==========\n\n")

# Total AUC physical effort cross-task
cat("Total AUC Physical Effort Cross-Task Correlations:\n")
total_auc_cross <- bind_rows(
  cdt_total$physical_effects %>% mutate(task = "CDT"),
  adt_total$physical_effects %>% mutate(task = "ADT"),
  vdt_total$physical_effects %>% mutate(task = "VDT")
) %>%
  group_by(sub, task) %>%
  summarise(pupil_physical_effect = mean(pupil_physical_effect), .groups = "drop") %>%
  pivot_wider(names_from = task, values_from = pupil_physical_effect) %>%
  filter(complete.cases(.))

if (nrow(total_auc_cross) > 10) {
  cor_matrix <- cor(total_auc_cross[, c("CDT", "ADT", "VDT")], use = "complete.obs")
  print(round(cor_matrix, 3))
  
  # Extract specific correlations
  cat("\nADT-CDT: r =", round(cor_matrix["ADT", "CDT"], 3), "\n")
  cat("ADT-VDT: r =", round(cor_matrix["ADT", "VDT"], 3), "\n")
  cat("CDT-VDT: r =", round(cor_matrix["CDT", "VDT"], 3), "\n")
}

# Cognitive AUC cognitive effort cross-task (ADT & VDT only)
cat("\nCognitive AUC Cognitive Effort Cross-Task Correlations (ADT & VDT only):\n")
cognitive_auc_cross <- bind_rows(
  adt_cognitive$cognitive_effects %>% mutate(task = "ADT"),
  vdt_cognitive$cognitive_effects %>% mutate(task = "VDT")
) %>%
  group_by(sub, task) %>%
  summarise(pupil_cognitive_effect = mean(pupil_cognitive_effect), .groups = "drop") %>%
  pivot_wider(names_from = task, values_from = pupil_cognitive_effect) %>%
  filter(complete.cases(.))

if (nrow(cognitive_auc_cross) > 5) {
  cor_result <- cor.test(cognitive_auc_cross$ADT, cognitive_auc_cross$VDT)
  cat("ADT-VDT: r =", round(cor_result$estimate, 3), ", p =", format.pval(cor_result$p.value, digits = 3), "\n")
}

# Save all results
write_csv(cdt_total$physical_effects, file.path(RESULTS_DIR, "cdt_total_auc_physical_effects.csv"))
write_csv(adt_total$physical_effects, file.path(RESULTS_DIR, "adt_total_auc_physical_effects.csv"))
write_csv(adt_total$cognitive_effects, file.path(RESULTS_DIR, "adt_total_auc_cognitive_effects.csv"))
write_csv(vdt_total$physical_effects, file.path(RESULTS_DIR, "vdt_total_auc_physical_effects.csv"))
write_csv(vdt_total$cognitive_effects, file.path(RESULTS_DIR, "vdt_total_auc_cognitive_effects.csv"))
write_csv(adt_cognitive$physical_effects, file.path(RESULTS_DIR, "adt_cognitive_auc_physical_effects.csv"))
write_csv(adt_cognitive$cognitive_effects, file.path(RESULTS_DIR, "adt_cognitive_auc_cognitive_effects.csv"))
write_csv(vdt_cognitive$physical_effects, file.path(RESULTS_DIR, "vdt_cognitive_auc_physical_effects.csv"))
write_csv(vdt_cognitive$cognitive_effects, file.path(RESULTS_DIR, "vdt_cognitive_auc_cognitive_effects.csv"))
write_csv(total_auc_cross, file.path(RESULTS_DIR, "total_auc_physical_cross_task.csv"))
write_csv(cognitive_auc_cross, file.path(RESULTS_DIR, "cognitive_auc_cognitive_cross_task.csv"))

cat("\n=== ANALYSIS COMPLETE ===\n")
cat("Results saved to:", RESULTS_DIR, "\n")
cat("\n📊 Summary:\n")
cat("✅ Total AUC: All 3 tasks analyzed\n")
cat("✅ Cognitive AUC: ADT & VDT only (CDT skipped per Lani's recommendations)\n")
cat("✅ CDT: Physical effort effects only\n")
cat("✅ Cross-task consistency: Calculated for interpretable effects\n")







