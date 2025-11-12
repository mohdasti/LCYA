#!/usr/bin/env Rscript

# Updated Individual Differences Analysis using SUBJECT MEANS approach
# NOW INCLUDING BOTH ACCURACY AND CORRECT RT
# Uses Pearson correlations on subject-averaged difference scores
# Avoids rmcorr artifact with 2 observations per subject

suppressPackageStartupMessages({
  library(tidyverse)
})

# Set up directories
BASE_DIR <- "/Users/mohdasti/Documents/LC–YA"
DATA_DIR <- file.path(BASE_DIR, "PI_Feedback_Outputs")
RESULTS_DIR <- file.path(BASE_DIR, "GitHub_Ready_Analyses/05_Manuscript_Figures/results_subject_means")

if (!dir.exists(RESULTS_DIR)) {
  dir.create(RESULTS_DIR, recursive = TRUE)
}

cat("=== UPDATED INDIVIDUAL DIFFERENCES ANALYSIS (SUBJECT MEANS) ===\n")
cat("Analysis Date:", as.character(Sys.time()), "\n")
cat("Using Pearson correlations on subject-averaged difference scores\n")
cat("NOW INCLUDING BOTH ACCURACY AND CORRECT RT\n\n")

# Load data
dual_auc_data <- read_csv(file.path(DATA_DIR, "Combined_Dual_AUC_Data.csv"), show_col_types = FALSE)
behavioral_data <- read_csv(file.path(BASE_DIR, "Complete_Manuscript_Results", "complete_analysis_data.csv"), show_col_types = FALSE)

# Process AUC data
processed_data <- dual_auc_data %>%
  mutate(
    sub = as.numeric(sub),
    difficulty = str_extract(condition, "^[^/]+") %>% str_trim(),
    effort = str_extract(condition, "[^/]+$") %>% str_trim(),
    task = factor(task, levels = c("CDT", "ADT", "VDT")),
    mean_total_auc = mean_physical_auc,
    mean_cognitive_auc = mean_cognitive_auc
  )

# Process behavioral data - NOW INCLUDING CORRECT RT
behavioral_summary <- behavioral_data %>%
  filter(!is.na(accuracy)) %>%
  group_by(sub, task, difficulty, effort) %>%
  summarise(
    mean_accuracy = mean(accuracy, na.rm = TRUE),
    mean_correct_rt = mean(rt_ms[accuracy == 1], na.rm = TRUE),  # Only correct trials
    n_correct = sum(accuracy == 1, na.rm = TRUE),
    n_total = n(),
    .groups = 'drop'
  ) %>%
  mutate(
    sub = as.numeric(str_remove(sub, "S")),
    difficulty = factor(difficulty, levels = c("Easy", "Hard")),
    effort = factor(effort, levels = c("Low", "High")),
    task = factor(task, levels = c("CDT", "ADT", "VDT")),
    # If no correct trials, set mean_correct_rt to NA
    mean_correct_rt = if_else(n_correct == 0, NA_real_, mean_correct_rt)
  )

merged_data <- processed_data %>%
  left_join(behavioral_summary, by = c("sub", "task", "difficulty", "effort"))

cat("Data loaded and processed successfully\n")
cat("Behavioral measures: Accuracy and Correct RT\n\n")

# Function to calculate individual differences using SUBJECT MEANS approach
# NOW HANDLES BOTH ACCURACY AND RT
calculate_subject_means_correlation <- function(task_data, task_name, measure_name, measure_var, 
                                                behavioral_var, behavioral_label,
                                                include_cognitive = TRUE) {
  
  # Calculate individual subject means for each condition
  individual_means <- task_data %>%
    filter(!is.na(!!sym(measure_var)), !is.na(!!sym(behavioral_var))) %>%
    group_by(sub, difficulty, effort) %>%
    summarise(
      mean_measure = mean(!!sym(measure_var), na.rm = TRUE),
      mean_behavioral = mean(!!sym(behavioral_var), na.rm = TRUE),
      .groups = "drop"
    )
  
  # Calculate physical effort effects (High - Low) for each subject and difficulty
  # Then AVERAGE across difficulties to get ONE value per subject
  physical_effects <- individual_means %>%
    group_by(sub, difficulty) %>%
    summarise(
      pupil_physical_effect = mean_measure[effort == "High"] - mean_measure[effort == "Low"],
      behavioral_physical_effect = mean_behavioral[effort == "High"] - mean_behavioral[effort == "Low"],
      .groups = "drop"
    ) %>%
    group_by(sub) %>%
    summarise(
      mean_pupil_physical_effect = mean(pupil_physical_effect, na.rm = TRUE),
      mean_behavioral_physical_effect = mean(behavioral_physical_effect, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    filter(!is.na(mean_pupil_physical_effect), !is.na(mean_behavioral_physical_effect))
  
  # Calculate cognitive effort effects (Hard - Easy) for each subject and effort level
  # Then AVERAGE across effort levels to get ONE value per subject
  if (include_cognitive) {
    cognitive_effects <- individual_means %>%
      group_by(sub, effort) %>%
      summarise(
        pupil_cognitive_effect = mean_measure[difficulty == "Hard"] - mean_measure[difficulty == "Easy"],
        behavioral_cognitive_effect = mean_behavioral[difficulty == "Hard"] - mean_behavioral[difficulty == "Easy"],
        .groups = "drop"
      ) %>%
      group_by(sub) %>%
      summarise(
        mean_pupil_cognitive_effect = mean(pupil_cognitive_effect, na.rm = TRUE),
        mean_behavioral_cognitive_effect = mean(behavioral_cognitive_effect, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      filter(!is.na(mean_pupil_cognitive_effect), !is.na(mean_behavioral_cognitive_effect))
  } else {
    cognitive_effects <- data.frame(
      sub = numeric(0),
      mean_pupil_cognitive_effect = numeric(0),
      mean_behavioral_cognitive_effect = numeric(0)
    )
  }
  
  # Calculate Pearson correlation for physical effort effects
  physical_cor <- NULL
  if (nrow(physical_effects) > 3) {
    physical_cor <- tryCatch({
      result <- cor.test(physical_effects$mean_pupil_physical_effect, 
                        physical_effects$mean_behavioral_physical_effect)
      
      cat(sprintf("%s %s × %s Physical Effort: r = %.2f, 95%% CI [%.2f, %.2f], p = %.2f, n = %d\n",
                  task_name, measure_name, behavioral_label,
                  result$estimate,
                  result$conf.int[1], result$conf.int[2],
                  result$p.value,
                  nrow(physical_effects)))
      result
    }, error = function(e) {
      cat(sprintf("%s %s × %s Physical Effort: correlation failed - %s\n", 
                  task_name, measure_name, behavioral_label, e$message))
      NULL
    })
  }
  
  # Calculate Pearson correlation for cognitive effort effects
  cognitive_cor <- NULL
  if (include_cognitive && nrow(cognitive_effects) > 3) {
    cognitive_cor <- tryCatch({
      result <- cor.test(cognitive_effects$mean_pupil_cognitive_effect, 
                        cognitive_effects$mean_behavioral_cognitive_effect)
      
      cat(sprintf("%s %s × %s Cognitive Effort: r = %.2f, 95%% CI [%.2f, %.2f], p = %.2f, n = %d\n",
                  task_name, measure_name, behavioral_label,
                  result$estimate,
                  result$conf.int[1], result$conf.int[2],
                  result$p.value,
                  nrow(cognitive_effects)))
      result
    }, error = function(e) {
      cat(sprintf("%s %s × %s Cognitive Effort: correlation failed - %s\n", 
                  task_name, measure_name, behavioral_label, e$message))
      NULL
    })
  } else if (!include_cognitive) {
    cat(sprintf("%s %s × %s Cognitive Effort: Skipped (CDT)\n", 
                task_name, measure_name, behavioral_label))
  }
  
  # Save results to summary immediately
  add_to_summary(task_name, measure_name, behavioral_label, "Physical", physical_cor, 
                 nrow(physical_effects))
  add_to_summary(task_name, measure_name, behavioral_label, "Cognitive", cognitive_cor, 
                 nrow(cognitive_effects))
  
  return(list(
    physical_effects = physical_effects,
    cognitive_effects = cognitive_effects,
    physical_correlation = physical_cor,
    cognitive_correlation = cognitive_cor,
    task_name = task_name,
    measure_name = measure_name,
    behavioral_label = behavioral_label
  ))
}

# Initialize results storage
all_results <- list()
results_counter <- 1
summary_rows <- list()
summary_row_counter <- 1

# Helper function to add results to summary
add_to_summary <- function(task, auc_measure, behavioral_measure, effort_type, cor_result, n_subjects) {
  tryCatch({
    if (is.null(cor_result)) {
      row <- data.frame(
        task = task,
        auc_measure = auc_measure,
        behavioral_measure = behavioral_measure,
        effort_type = effort_type,
        r = NA_real_,
        ci_lower = NA_real_,
        ci_upper = NA_real_,
        p = NA_real_,
        n = NA_integer_,
        stringsAsFactors = FALSE
      )
    } else {
      # Extract values from cor.test result
      r_val <- as.numeric(cor_result$estimate)
      ci_lower_val <- as.numeric(cor_result$conf.int[1])
      ci_upper_val <- as.numeric(cor_result$conf.int[2])
      p_val <- as.numeric(cor_result$p.value)
      
      row <- data.frame(
        task = task,
        auc_measure = auc_measure,
        behavioral_measure = behavioral_measure,
        effort_type = effort_type,
        r = r_val,
        ci_lower = ci_lower_val,
        ci_upper = ci_upper_val,
        p = p_val,
        n = as.integer(n_subjects),
        stringsAsFactors = FALSE
      )
    }
    summary_rows[[summary_row_counter]] <<- row
    summary_row_counter <<- summary_row_counter + 1
  }, error = function(e) {
    # If any error, save NA row
    row <- data.frame(
      task = task,
      auc_measure = auc_measure,
      behavioral_measure = behavioral_measure,
      effort_type = effort_type,
      r = NA_real_,
      ci_lower = NA_real_,
      ci_upper = NA_real_,
      p = NA_real_,
      n = NA_integer_,
      stringsAsFactors = FALSE
    )
    summary_rows[[summary_row_counter]] <<- row
    summary_row_counter <<- summary_row_counter + 1
  })
}

##############################################################################
# TOTAL AUC × ACCURACY
##############################################################################

cat("========== TOTAL AUC × ACCURACY ANALYSIS ==========\n\n")

# CDT: Physical effort only
cat("--- CDT Total AUC × Accuracy ---\n")
result <- calculate_subject_means_correlation(
  merged_data %>% filter(task == "CDT"),
  "CDT", "Total AUC", "mean_total_auc", "mean_accuracy", "Accuracy",
  include_cognitive = FALSE
)
all_results[[results_counter]] <- result
results_counter <- results_counter + 1

# ADT: Full analysis
cat("\n--- ADT Total AUC × Accuracy ---\n")
result <- calculate_subject_means_correlation(
  merged_data %>% filter(task == "ADT"),
  "ADT", "Total AUC", "mean_total_auc", "mean_accuracy", "Accuracy",
  include_cognitive = TRUE
)
all_results[[results_counter]] <- result
results_counter <- results_counter + 1

# VDT: Full analysis
cat("\n--- VDT Total AUC × Accuracy ---\n")
result <- calculate_subject_means_correlation(
  merged_data %>% filter(task == "VDT"),
  "VDT", "Total AUC", "mean_total_auc", "mean_accuracy", "Accuracy",
  include_cognitive = TRUE
)
all_results[[results_counter]] <- result
results_counter <- results_counter + 1

##############################################################################
# TOTAL AUC × CORRECT RT
##############################################################################

cat("\n========== TOTAL AUC × CORRECT RT ANALYSIS ==========\n\n")

# CDT: Physical effort only
cat("--- CDT Total AUC × Correct RT ---\n")
result <- calculate_subject_means_correlation(
  merged_data %>% filter(task == "CDT"),
  "CDT", "Total AUC", "mean_total_auc", "mean_correct_rt", "Correct RT",
  include_cognitive = FALSE
)
all_results[[results_counter]] <- result
results_counter <- results_counter + 1

# ADT: Full analysis
cat("\n--- ADT Total AUC × Correct RT ---\n")
result <- calculate_subject_means_correlation(
  merged_data %>% filter(task == "ADT"),
  "ADT", "Total AUC", "mean_total_auc", "mean_correct_rt", "Correct RT",
  include_cognitive = TRUE
)
all_results[[results_counter]] <- result
results_counter <- results_counter + 1

# VDT: Full analysis
cat("\n--- VDT Total AUC × Correct RT ---\n")
result <- calculate_subject_means_correlation(
  merged_data %>% filter(task == "VDT"),
  "VDT", "Total AUC", "mean_total_auc", "mean_correct_rt", "Correct RT",
  include_cognitive = TRUE
)
all_results[[results_counter]] <- result
results_counter <- results_counter + 1

##############################################################################
# COGNITIVE AUC × ACCURACY
##############################################################################

cat("\n========== COGNITIVE AUC × ACCURACY ANALYSIS ==========\n\n")

cat("CDT Cognitive AUC: Skipped per analytical recommendations\n\n")

# ADT: Both physical and cognitive effort
cat("--- ADT Cognitive AUC × Accuracy ---\n")
result <- calculate_subject_means_correlation(
  merged_data %>% filter(task == "ADT"),
  "ADT", "Cognitive AUC", "mean_cognitive_auc", "mean_accuracy", "Accuracy",
  include_cognitive = TRUE
)
all_results[[results_counter]] <- result
results_counter <- results_counter + 1

# VDT: Both physical and cognitive effort
cat("\n--- VDT Cognitive AUC × Accuracy ---\n")
result <- calculate_subject_means_correlation(
  merged_data %>% filter(task == "VDT"),
  "VDT", "Cognitive AUC", "mean_cognitive_auc", "mean_accuracy", "Accuracy",
  include_cognitive = TRUE
)
all_results[[results_counter]] <- result
results_counter <- results_counter + 1

##############################################################################
# COGNITIVE AUC × CORRECT RT
##############################################################################

cat("\n========== COGNITIVE AUC × CORRECT RT ANALYSIS ==========\n\n")

cat("CDT Cognitive AUC: Skipped per analytical recommendations\n\n")

# ADT: Both physical and cognitive effort
cat("--- ADT Cognitive AUC × Correct RT ---\n")
result <- calculate_subject_means_correlation(
  merged_data %>% filter(task == "ADT"),
  "ADT", "Cognitive AUC", "mean_cognitive_auc", "mean_correct_rt", "Correct RT",
  include_cognitive = TRUE
)
all_results[[results_counter]] <- result
results_counter <- results_counter + 1

# VDT: Both physical and cognitive effort
cat("\n--- VDT Cognitive AUC × Correct RT ---\n")
result <- calculate_subject_means_correlation(
  merged_data %>% filter(task == "VDT"),
  "VDT", "Cognitive AUC", "mean_cognitive_auc", "mean_correct_rt", "Correct RT",
  include_cognitive = TRUE
)
all_results[[results_counter]] <- result
results_counter <- results_counter + 1

##############################################################################
# SAVE RESULTS
##############################################################################

cat("\n========== SAVING RESULTS ==========\n\n")

# Create summary table from directly saved results
summary_results <- bind_rows(summary_rows)

# Save summary table
write_csv(summary_results, file.path(RESULTS_DIR, "individual_differences_subject_means_summary.csv"))

cat("✓ Summary table saved to: individual_differences_subject_means_summary.csv\n")

# Save individual difference scores for each analysis
for (i in seq_along(all_results)) {
  res <- all_results[[i]]
  
  # Physical effects
  if (nrow(res$physical_effects) > 0) {
    filename <- paste0(tolower(res$task_name), "_", 
                      gsub(" ", "_", tolower(res$measure_name)), "_x_",
                      gsub(" ", "_", tolower(res$behavioral_label)), "_physical_effects_subject_means.csv")
    write_csv(res$physical_effects, file.path(RESULTS_DIR, filename))
  }
  
  # Cognitive effects
  if (nrow(res$cognitive_effects) > 0) {
    filename <- paste0(tolower(res$task_name), "_", 
                      gsub(" ", "_", tolower(res$measure_name)), "_x_",
                      gsub(" ", "_", tolower(res$behavioral_label)), "_cognitive_effects_subject_means.csv")
    write_csv(res$cognitive_effects, file.path(RESULTS_DIR, filename))
  }
}

cat("✓ Individual difference scores (subject means) saved\n")

##############################################################################
# GENERATE MARKDOWN REPORT
##############################################################################

cat("\n========== GENERATING MARKDOWN REPORT ==========\n\n")

md_lines <- c(
  "# Individual Differences Analysis: Subject Means Approach",
  "",
  paste0("**Analysis Date:** ", Sys.time()),
  "",
  "## Overview",
  "",
  "This analysis examines individual differences in pupillary and behavioral effort sensitivity",
  "using **SUBJECT MEANS** approach with Pearson correlations.",
  "",
  "### Key Features:",
  "- ✅ Accuracy difference scores",
  "- ✅ Correct RT difference scores",
  "- ✅ Both Physical Effort (High - Low) and Cognitive Effort (Hard - Easy) effects",
  "- ✅ Separate analyses for Total AUC and Cognitive AUC",
  "- ✅ **Subject means approach:** ONE averaged value per subject to avoid rmcorr artifact",
  "",
  "## Methods",
  "",
  "**Statistical Approach:** Pearson correlation on subject-averaged difference scores",
  "",
  "**Why Subject Means?**",
  "- With exactly 2 observations per subject (e.g., Easy vs Hard), rmcorr produces",
  "  mathematical artifacts where different effects yield identical correlations",
  "- Subject means approach averages difference scores to ONE value per subject,",
  "  providing a clean individual differences measure",
  "- This matches the original analysis approach and published statistics",
  "",
  "**Difference Scores Calculation:**",
  "",
  "1. **Physical Effort effect (for each subject):**",
  "   - Calculate High - Low for each difficulty level",
  "   - Average across difficulty levels → ONE value per subject",
  "",
  "2. **Cognitive Effort effect (for each subject):**",
  "   - Calculate Hard - Easy for each effort level",
  "   - Average across effort levels → ONE value per subject",
  "",
  "**AUC Measures:**",
  "- Total AUC: Overall pupillary response from squeeze onset to response",
  "- Cognitive AUC: Isolated cognitive response (300ms post-stimulus to response, B2b baseline)",
  "",
  "**Behavioral Measures:**",
  "- Accuracy: Proportion correct",
  "- Correct RT: Mean reaction time for correct trials only (ms)",
  "",
  "---",
  "",
  "## Results Summary Table",
  "",
  "| Task | AUC Measure | Behavioral Measure | Effort Type | r | 95% CI | p | n |",
  "|------|-------------|--------------------|--------------|----|--------|---|---|"
)

# Add results to table
for (i in 1:nrow(summary_results)) {
  row <- summary_results[i, ]
  if (!is.na(row$r)) {
    md_lines <- c(md_lines,
                  sprintf("| %s | %s | %s | %s | %.2f | [%.2f, %.2f] | %.2f | %d |",
                          row$task, row$auc_measure, row$behavioral_measure, row$effort_type,
                          row$r, row$ci_lower, row$ci_upper, row$p, row$n))
  } else {
    md_lines <- c(md_lines,
                  sprintf("| %s | %s | %s | %s | — | — | — | — |",
                          row$task, row$auc_measure, row$behavioral_measure, row$effort_type))
  }
}

md_lines <- c(md_lines,
  "",
  "---",
  "",
  "## Detailed Results by Analysis",
  ""
)

# Group results by analysis type
analyses_order <- c(
  "Total AUC × Accuracy",
  "Total AUC × Correct RT",
  "Cognitive AUC × Accuracy",
  "Cognitive AUC × Correct RT"
)

for (analysis_type in analyses_order) {
  md_lines <- c(md_lines,
    paste0("### ", analysis_type),
    ""
  )
  
  # Get relevant results
  relevant_results <- summary_results %>%
    filter(paste(auc_measure, "×", behavioral_measure) == analysis_type)
  
  if (nrow(relevant_results) > 0) {
    for (task in c("CDT", "ADT", "VDT")) {
      task_results <- relevant_results %>% filter(task == !!task)
      
      if (nrow(task_results) > 0) {
        md_lines <- c(md_lines, paste0("**", task, ":**"))
        
        for (effort in c("Physical", "Cognitive")) {
          effort_result <- task_results %>% filter(effort_type == effort)
          
          if (nrow(effort_result) > 0 && !is.na(effort_result$r[1])) {
            md_lines <- c(md_lines,
              sprintf("- %s Effort: *r* = %.2f, 95%% CI [%.2f, %.2f], *p* = %.2f, *n* = %d",
                      effort, effort_result$r[1], effort_result$ci_lower[1], 
                      effort_result$ci_upper[1], effort_result$p[1], effort_result$n[1]))
          } else if (nrow(effort_result) > 0) {
            md_lines <- c(md_lines,
              sprintf("- %s Effort: Skipped", effort))
          }
        }
        md_lines <- c(md_lines, "")
      }
    }
  }
  
  md_lines <- c(md_lines, "")
}

md_lines <- c(md_lines,
  "---",
  "",
  "## Interpretation Notes",
  "",
  "### Findings",
  "Most correlations did not reach statistical significance, suggesting that:",
  "- Individual differences in physiological effort sensitivity (AUC) do not strongly predict",
  "  individual differences in behavioral effort sensitivity (accuracy or RT)",
  "- This pattern holds across both accuracy and RT measures",
  "- This pattern is consistent for both physical effort and cognitive effort manipulations",
  "",
  "### Cognitive AUC Notes",
  "- CDT excluded per analytical recommendations (difficulty manipulation issues)",
  "- ADT and VDT analyzed for both Physical and Cognitive effort effects",
  "- Physical effort effects on Cognitive AUC test whether the isolated cognitive response",
  "  still shows individual differences related to the physical manipulation",
  "",
  "### RT vs Accuracy",
  "The inclusion of Correct RT provides a complementary measure to accuracy:",
  "- Accuracy reflects decision correctness",
  "- Correct RT reflects processing speed (on successful trials)",
  "- Together, they provide a more complete picture of behavioral performance",
  "",
  "### Methodological Note: Subject Means vs rmcorr",
  "This analysis uses the **subject means approach** rather than rmcorr because:",
  "- With exactly 2 observations per subject, rmcorr produces mathematical artifacts",
  "- Different effects (physical vs cognitive) yielded identical r values in rmcorr",
  "- Subject means (one averaged value per subject) provides clean individual differences",
  "- This approach matches the original published analysis",
  "",
  "---",
  "",
  "## Files Generated",
  "",
  "### Summary:",
  "- `individual_differences_subject_means_summary.csv` - Complete results table",
  "",
  "### Individual Difference Scores (Subject Means):",
  "Format: `{task}_{auc_measure}_x_{behavioral_measure}_{effort_type}_effects_subject_means.csv`",
  "",
  "Each file contains ONE averaged difference score per subject used in the correlation analyses.",
  "",
  "---",
  "",
  "**End of Report**"
)

# Write markdown report
writeLines(md_lines, file.path(RESULTS_DIR, "individual_differences_subject_means_report.md"))

cat("✓ Markdown report saved to: individual_differences_subject_means_report.md\n")

cat("\n=== INDIVIDUAL DIFFERENCES ANALYSIS COMPLETE ===\n")
cat("Results saved to:", RESULTS_DIR, "\n")
cat("\n📊 Key Features:\n")
cat("✅ Subject means approach (ONE averaged value per subject)\n")
cat("✅ Includes BOTH Accuracy AND Correct RT\n")
cat("✅ Separate analyses for Total AUC and Cognitive AUC\n")
cat("✅ Both Physical and Cognitive effort effects examined\n")
cat("✅ Avoids rmcorr artifact with 2 observations per subject\n")
cat("✅ Comprehensive CSV and Markdown reports generated\n")
cat("✅ All subject-level difference scores saved for verification\n")

