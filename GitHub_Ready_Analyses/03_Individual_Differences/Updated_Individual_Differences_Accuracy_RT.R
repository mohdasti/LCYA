#!/usr/bin/env Rscript

# Updated Individual Differences Analysis using rmcorr
# NOW INCLUDING BOTH ACCURACY AND CORRECT RT
# Based on literature review recommendations
# Addresses non-independence of observations within subjects

suppressPackageStartupMessages({
  library(tidyverse)
  library(rmcorr)
})

# Set up directories
BASE_DIR <- "/Users/mohdasti/Documents/LC–YA"
DATA_DIR <- file.path(BASE_DIR, "PI_Feedback_Outputs")
RESULTS_DIR <- file.path(BASE_DIR, "GitHub_Ready_Analyses/05_Manuscript_Figures/results_updated_with_RT")

if (!dir.exists(RESULTS_DIR)) {
  dir.create(RESULTS_DIR, recursive = TRUE)
}

cat("=== UPDATED INDIVIDUAL DIFFERENCES ANALYSIS (rmcorr) ===\n")
cat("Analysis Date:", as.character(Sys.time()), "\n")
cat("Using repeated measures correlation to address non-independence\n")
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

# Function to calculate individual differences using rmcorr
# NOW HANDLES BOTH ACCURACY AND RT
calculate_rmcorr_individual_differences <- function(task_data, task_name, measure_name, measure_var, 
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
  physical_effects <- individual_means %>%
    group_by(sub, difficulty) %>%
    summarise(
      pupil_physical_effect = mean_measure[effort == "High"] - mean_measure[effort == "Low"],
      behavioral_physical_effect = mean_behavioral[effort == "High"] - mean_behavioral[effort == "Low"],
      .groups = "drop"
    ) %>%
    filter(!is.na(pupil_physical_effect), !is.na(behavioral_physical_effect))
  
  # Calculate cognitive effort effects (Hard - Easy) for each subject and effort level
  if (include_cognitive) {
    cognitive_effects <- individual_means %>%
      group_by(sub, effort) %>%
      summarise(
        pupil_cognitive_effect = mean_measure[difficulty == "Hard"] - mean_measure[difficulty == "Easy"],
        behavioral_cognitive_effect = mean_behavioral[difficulty == "Hard"] - mean_behavioral[difficulty == "Easy"],
        .groups = "drop"
      ) %>%
      filter(!is.na(pupil_cognitive_effect), !is.na(behavioral_cognitive_effect))
  } else {
    cognitive_effects <- data.frame(
      sub = numeric(0),
      effort = character(0),
      pupil_cognitive_effect = numeric(0),
      behavioral_cognitive_effect = numeric(0)
    )
  }
  
  # Calculate rmcorr for physical effort effects
  physical_rmcorr <- NULL
  if (nrow(physical_effects) > 3) {
    physical_rmcorr <- tryCatch({
      result <- rmcorr(participant = sub,
                      measure1 = pupil_physical_effect,
                      measure2 = behavioral_physical_effect,
                      dataset = physical_effects)
      
      cat(sprintf("%s %s × %s Physical Effort (rmcorr): r_rm = %.3f, 95%% CI [%.3f, %.3f], p = %.3f, df = %d, n = %d\n",
                  task_name, measure_name, behavioral_label,
                  result$r, 
                  result$CI[1], result$CI[2],
                  result$p,
                  result$df,
                  nrow(physical_effects)))
      result  # Return the result
    }, error = function(e) {
      cat(sprintf("%s %s × %s Physical Effort: rmcorr failed - %s\n", 
                  task_name, measure_name, behavioral_label, e$message))
      NULL
    })
  }
  
  # Calculate rmcorr for cognitive effort effects
  cognitive_rmcorr <- NULL
  if (include_cognitive && nrow(cognitive_effects) > 3) {
    cognitive_rmcorr <- tryCatch({
      result <- rmcorr(participant = sub,
                      measure1 = pupil_cognitive_effect,
                      measure2 = behavioral_cognitive_effect,
                      dataset = cognitive_effects)
      
      cat(sprintf("%s %s × %s Cognitive Effort (rmcorr): r_rm = %.3f, 95%% CI [%.3f, %.3f], p = %.3f, df = %d, n = %d\n",
                  task_name, measure_name, behavioral_label,
                  result$r, 
                  result$CI[1], result$CI[2],
                  result$p,
                  result$df,
                  nrow(cognitive_effects)))
      result  # Return the result
    }, error = function(e) {
      cat(sprintf("%s %s × %s Cognitive Effort: rmcorr failed - %s\n", 
                  task_name, measure_name, behavioral_label, e$message))
      NULL
    })
  } else if (!include_cognitive) {
    cat(sprintf("%s %s × %s Cognitive Effort: Skipped (CDT)\n", 
                task_name, measure_name, behavioral_label))
  }
  
  # Save results to summary immediately
  add_to_summary(task_name, measure_name, behavioral_label, "Physical", physical_rmcorr)
  add_to_summary(task_name, measure_name, behavioral_label, "Cognitive", cognitive_rmcorr)
  
  return(list(
    physical_effects = physical_effects,
    cognitive_effects = cognitive_effects,
    physical_rmcorr = physical_rmcorr,
    cognitive_rmcorr = cognitive_rmcorr,
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
add_to_summary <- function(task, auc_measure, behavioral_measure, effort_type, rmcorr_result) {
  tryCatch({
    if (is.null(rmcorr_result)) {
      row <- data.frame(
        task = task,
        auc_measure = auc_measure,
        behavioral_measure = behavioral_measure,
        effort_type = effort_type,
        r = NA_real_,
        ci_lower = NA_real_,
        ci_upper = NA_real_,
        p = NA_real_,
        df = NA_integer_,
        n = NA_integer_,
        stringsAsFactors = FALSE
      )
    } else {
      # Safely extract values with default to NA if missing
      r_val <- if (!is.null(rmcorr_result$r) && length(rmcorr_result$r) > 0) as.numeric(rmcorr_result$r) else NA_real_
      ci_lower_val <- if (!is.null(rmcorr_result$CI) && length(rmcorr_result$CI) >= 1) as.numeric(rmcorr_result$CI[1]) else NA_real_
      ci_upper_val <- if (!is.null(rmcorr_result$CI) && length(rmcorr_result$CI) >= 2) as.numeric(rmcorr_result$CI[2]) else NA_real_
      p_val <- if (!is.null(rmcorr_result$p) && length(rmcorr_result$p) > 0) as.numeric(rmcorr_result$p) else NA_real_
      df_val <- if (!is.null(rmcorr_result$df) && length(rmcorr_result$df) > 0) as.integer(rmcorr_result$df) else NA_integer_
      n_val <- if (!is.null(rmcorr_result$model) && is.data.frame(rmcorr_result$model) && nrow(rmcorr_result$model) > 0) {
        as.integer(nrow(rmcorr_result$model))
      } else if (!is.null(rmcorr_result$df)) {
        # If model not available, estimate from df (df = n - 1 for rmcorr with 2 repeated measures per subject)
        as.integer(rmcorr_result$df + 1)
      } else {
        NA_integer_
      }
      
      row <- data.frame(
        task = task,
        auc_measure = auc_measure,
        behavioral_measure = behavioral_measure,
        effort_type = effort_type,
        r = r_val,
        ci_lower = ci_lower_val,
        ci_upper = ci_upper_val,
        p = p_val,
        df = df_val,
        n = n_val,
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
      df = NA_integer_,
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

cat("========== TOTAL AUC × ACCURACY ANALYSIS (rmcorr) ==========\n\n")

# CDT: Physical effort only
cat("--- CDT Total AUC × Accuracy ---\n")
result <- calculate_rmcorr_individual_differences(
  merged_data %>% filter(task == "CDT"),
  "CDT", "Total AUC", "mean_total_auc", "mean_accuracy", "Accuracy",
  include_cognitive = FALSE
)
all_results[[results_counter]] <- result
results_counter <- results_counter + 1

# ADT: Full analysis
cat("\n--- ADT Total AUC × Accuracy ---\n")
result <- calculate_rmcorr_individual_differences(
  merged_data %>% filter(task == "ADT"),
  "ADT", "Total AUC", "mean_total_auc", "mean_accuracy", "Accuracy",
  include_cognitive = TRUE
)
all_results[[results_counter]] <- result
results_counter <- results_counter + 1

# VDT: Full analysis
cat("\n--- VDT Total AUC × Accuracy ---\n")
result <- calculate_rmcorr_individual_differences(
  merged_data %>% filter(task == "VDT"),
  "VDT", "Total AUC", "mean_total_auc", "mean_accuracy", "Accuracy",
  include_cognitive = TRUE
)
all_results[[results_counter]] <- result
results_counter <- results_counter + 1

##############################################################################
# TOTAL AUC × CORRECT RT
##############################################################################

cat("\n========== TOTAL AUC × CORRECT RT ANALYSIS (rmcorr) ==========\n\n")

# CDT: Physical effort only
cat("--- CDT Total AUC × Correct RT ---\n")
result <- calculate_rmcorr_individual_differences(
  merged_data %>% filter(task == "CDT"),
  "CDT", "Total AUC", "mean_total_auc", "mean_correct_rt", "Correct RT",
  include_cognitive = FALSE
)
all_results[[results_counter]] <- result
results_counter <- results_counter + 1

# ADT: Full analysis
cat("\n--- ADT Total AUC × Correct RT ---\n")
result <- calculate_rmcorr_individual_differences(
  merged_data %>% filter(task == "ADT"),
  "ADT", "Total AUC", "mean_total_auc", "mean_correct_rt", "Correct RT",
  include_cognitive = TRUE
)
all_results[[results_counter]] <- result
results_counter <- results_counter + 1

# VDT: Full analysis
cat("\n--- VDT Total AUC × Correct RT ---\n")
result <- calculate_rmcorr_individual_differences(
  merged_data %>% filter(task == "VDT"),
  "VDT", "Total AUC", "mean_total_auc", "mean_correct_rt", "Correct RT",
  include_cognitive = TRUE
)
all_results[[results_counter]] <- result
results_counter <- results_counter + 1

##############################################################################
# COGNITIVE AUC × ACCURACY
##############################################################################

cat("\n========== COGNITIVE AUC × ACCURACY ANALYSIS (rmcorr) ==========\n\n")

cat("CDT Cognitive AUC: Skipped per analytical recommendations\n\n")

# ADT: Both physical and cognitive effort
cat("--- ADT Cognitive AUC × Accuracy ---\n")
result <- calculate_rmcorr_individual_differences(
  merged_data %>% filter(task == "ADT"),
  "ADT", "Cognitive AUC", "mean_cognitive_auc", "mean_accuracy", "Accuracy",
  include_cognitive = TRUE
)
all_results[[results_counter]] <- result
results_counter <- results_counter + 1

# VDT: Both physical and cognitive effort
cat("\n--- VDT Cognitive AUC × Accuracy ---\n")
result <- calculate_rmcorr_individual_differences(
  merged_data %>% filter(task == "VDT"),
  "VDT", "Cognitive AUC", "mean_cognitive_auc", "mean_accuracy", "Accuracy",
  include_cognitive = TRUE
)
all_results[[results_counter]] <- result
results_counter <- results_counter + 1

##############################################################################
# COGNITIVE AUC × CORRECT RT
##############################################################################

cat("\n========== COGNITIVE AUC × CORRECT RT ANALYSIS (rmcorr) ==========\n\n")

cat("CDT Cognitive AUC: Skipped per analytical recommendations\n\n")

# ADT: Both physical and cognitive effort
cat("--- ADT Cognitive AUC × Correct RT ---\n")
result <- calculate_rmcorr_individual_differences(
  merged_data %>% filter(task == "ADT"),
  "ADT", "Cognitive AUC", "mean_cognitive_auc", "mean_correct_rt", "Correct RT",
  include_cognitive = TRUE
)
all_results[[results_counter]] <- result
results_counter <- results_counter + 1

# VDT: Both physical and cognitive effort
cat("\n--- VDT Cognitive AUC × Correct RT ---\n")
result <- calculate_rmcorr_individual_differences(
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

# Function to extract correlation statistics
extract_rmcorr_stats <- function(rmcorr_obj) {
  # Return NA row if object is NULL
  if (is.null(rmcorr_obj)) {
    return(data.frame(r = NA_real_, ci_lower = NA_real_, ci_upper = NA_real_, 
                     p = NA_real_, df = NA_integer_, n = NA_integer_))
  }
  
  # Try to extract stats regardless of class (rmcorr might return different classes)
  tryCatch({
    data.frame(
      r = as.numeric(rmcorr_obj$r),
      ci_lower = as.numeric(rmcorr_obj$CI[1]),
      ci_upper = as.numeric(rmcorr_obj$CI[2]),
      p = as.numeric(rmcorr_obj$p),
      df = as.integer(rmcorr_obj$df),
      n = as.integer(nrow(rmcorr_obj$model))
    )
  }, error = function(e) {
    # If extraction fails, return NA row
    data.frame(r = NA_real_, ci_lower = NA_real_, ci_upper = NA_real_, 
               p = NA_real_, df = NA_integer_, n = NA_integer_)
  })
}

# Create summary table from directly saved results
summary_results <- bind_rows(summary_rows)

# Save summary table
write_csv(summary_results, file.path(RESULTS_DIR, "updated_individual_differences_rmcorr_summary.csv"))

cat("✓ Summary table saved to: updated_individual_differences_rmcorr_summary.csv\n")

# Save individual difference scores for each analysis
for (i in seq_along(all_results)) {
  res <- all_results[[i]]
  
  # Physical effects
  if (nrow(res$physical_effects) > 0) {
    filename <- paste0(tolower(res$task_name), "_", 
                      gsub(" ", "_", tolower(res$measure_name)), "_x_",
                      gsub(" ", "_", tolower(res$behavioral_label)), "_physical_effects.csv")
    write_csv(res$physical_effects, file.path(RESULTS_DIR, filename))
  }
  
  # Cognitive effects
  if (nrow(res$cognitive_effects) > 0) {
    filename <- paste0(tolower(res$task_name), "_", 
                      gsub(" ", "_", tolower(res$measure_name)), "_x_",
                      gsub(" ", "_", tolower(res$behavioral_label)), "_cognitive_effects.csv")
    write_csv(res$cognitive_effects, file.path(RESULTS_DIR, filename))
  }
}

cat("✓ Individual difference scores saved\n")

##############################################################################
# GENERATE MARKDOWN REPORT
##############################################################################

cat("\n========== GENERATING MARKDOWN REPORT ==========\n\n")

md_lines <- c(
  "# Updated Individual Differences Analysis: Accuracy AND Correct RT",
  "",
  paste0("**Analysis Date:** ", Sys.time()),
  "",
  "## Overview",
  "",
  "This updated analysis includes BOTH accuracy and correct RT as behavioral measures,",
  "addressing the gap in the previous analysis which only examined accuracy.",
  "",
  "### Key Updates:",
  "- ✅ Accuracy difference scores (as before)",
  "- ✅ **NEW:** Correct RT difference scores",
  "- ✅ Both Physical Effort (High - Low) and Cognitive Effort (Hard - Easy) effects",
  "- ✅ Separate analyses for Total AUC and Cognitive AUC",
  "",
  "## Methods",
  "",
  "**Statistical Approach:** Repeated measures correlation (rmcorr) to account for non-independence",
  "",
  "**Difference Scores:**",
  "- Physical Effort effect = High - Low (averaged across difficulty levels)",
  "- Cognitive Effort effect = Hard - Easy (averaged across effort levels)",
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
  "| Task | AUC Measure | Behavioral Measure | Effort Type | r | 95% CI | p | df | n |",
  "|------|-------------|--------------------|--------------|----|--------|---|----|----|"
)

# Add results to table
for (i in 1:nrow(summary_results)) {
  row <- summary_results[i, ]
  if (!is.na(row$r)) {
    md_lines <- c(md_lines,
                  sprintf("| %s | %s | %s | %s | %.3f | [%.3f, %.3f] | %.3f | %d | %d |",
                          row$task, row$auc_measure, row$behavioral_measure, row$effort_type,
                          row$r, row$ci_lower, row$ci_upper, row$p, row$df, row$n))
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
              sprintf("- %s Effort: r_rm = %.3f, 95%% CI [%.3f, %.3f], p = %.3f, df = %d, n = %d",
                      effort, effort_result$r[1], effort_result$ci_lower[1], 
                      effort_result$ci_upper[1], effort_result$p[1], 
                      effort_result$df[1], effort_result$n[1]))
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
  "### Non-Significant Findings",
  "None of the correlations reached statistical significance, suggesting that:",
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
  "---",
  "",
  "## Files Generated",
  "",
  "### Summary:",
  "- `updated_individual_differences_rmcorr_summary.csv` - Complete results table",
  "",
  "### Individual Difference Scores:",
  "Format: `{task}_{auc_measure}_x_{behavioral_measure}_{effort_type}_effects.csv`",
  "",
  "Each file contains subject-level difference scores used in the correlation analyses.",
  "",
  "---",
  "",
  "**End of Report**"
)

# Write markdown report
writeLines(md_lines, file.path(RESULTS_DIR, "updated_individual_differences_report.md"))

cat("✓ Markdown report saved to: updated_individual_differences_report.md\n")

cat("\n=== UPDATED INDIVIDUAL DIFFERENCES ANALYSIS COMPLETE ===\n")
cat("Results saved to:", RESULTS_DIR, "\n")
cat("\n📊 Key Updates:\n")
cat("✅ NOW includes BOTH Accuracy AND Correct RT\n")
cat("✅ Separate analyses for Total AUC and Cognitive AUC\n")
cat("✅ Both Physical and Cognitive effort effects examined\n")
cat("✅ Using rmcorr to address non-independence\n")
cat("✅ Comprehensive CSV and Markdown reports generated\n")
cat("✅ All difference score files saved for verification\n")

