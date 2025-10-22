#!/usr/bin/env Rscript

# LCYA AUC Analysis: Physical and Cognitive Effort
# Comprehensive pupillary response analysis using Area Under the Curve (AUC) approach
# Based on corrected baseline data with pre-anticipatory B0 [-1.0, -0.5s]

# Load required libraries
suppressPackageStartupMessages({
  library(tidyverse)
  library(data.table)
  library(pracma)  # For trapz function
  library(lme4)    # For mixed-effects models
  library(lmerTest) # For p-values
  library(ggplot2)
  library(patchwork)
})

# Set up directories
BASE_DIR <- "/Users/mohdasti/Documents/LC–YA"
DATA_DIR <- file.path(BASE_DIR, "100 Hz")
OUTPUT_DIR <- file.path(BASE_DIR, "PI_Feedback_Outputs")

# Create output directory if it doesn't exist
if (!dir.exists(OUTPUT_DIR)) {
  dir.create(OUTPUT_DIR, recursive = TRUE)
}

# Task configurations with corrected duration labels
task_configs <- list(
  CDT = list(
    task_name = "CDT",
    target_stimulus = "Arrow",
    response_label = "Response",
    cognitive_window_start = 4.8,  # 300ms after Arrow onset (~4.5s)
    cognitive_window_end = 6.3     # 1.5s window
  ),
  ADT = list(
    task_name = "ADT", 
    target_stimulus = "Stimulus",
    response_label = "Response",
    cognitive_window_start = 4.2,  # 300ms after Stimulus onset (~3.9s)
    cognitive_window_end = 5.7     # 1.5s window
  ),
  VDT = list(
    task_name = "VDT",
    target_stimulus = "Stimulus",
    response_label = "Response",
    cognitive_window_start = 4.2,  # 300ms after Stimulus onset (~3.9s)
    cognitive_window_end = 5.7     # 1.5s window
  )
)

# Function to load and preprocess data for a single task
load_task_data <- function(task_name) {
  cat("\n=== Loading", task_name, "Data ===\n")
  
  # Find all CSV files for this task
  task_files <- list.files(DATA_DIR, pattern = paste0(".*", task_name, "_DS100_merged\\.csv$"), full.names = TRUE)
  cat("Found", length(task_files), "files for", task_name, "\n")
  
  if (length(task_files) == 0) {
    stop("No data files found for task: ", task_name)
  }
  
  # Load and combine all files
  all_data <- map_dfr(task_files, function(file_path) {
    cat("Loaded", basename(file_path), "-", nrow(read_csv(file_path, show_col_types = FALSE)), "rows\n")
    data <- read_csv(file_path, show_col_types = FALSE)
    data$task_name <- task_name  # Add task name to each row
    return(data)
  })
  
  cat("Total rows loaded:", nrow(all_data), "\n")
  
  # Filter out stimLev == 0 (Standard trials) and create conditions
  # Task-specific stimLev mappings based on actual data:
  # CDT: 5, 20 (Easy) vs 45, 90 (Hard)
  # ADT: 4, 8 (Easy) vs 32, 128 (Hard)  
  # VDT: 0.04, 0.08 (Easy) vs 0.16, 0.32 (Hard)
  filtered_data <- all_data %>%
    filter(stimLev != 0) %>%
    mutate(
      difficulty = case_when(
        task_name == "CDT" & stimLev %in% c(5, 20) ~ "Easy",
        task_name == "CDT" & stimLev %in% c(45, 90) ~ "Hard",
        task_name == "ADT" & stimLev %in% c(4, 8) ~ "Easy", 
        task_name == "ADT" & stimLev %in% c(32, 128) ~ "Hard",
        task_name == "VDT" & stimLev %in% c(0.04, 0.08) ~ "Easy",
        task_name == "VDT" & stimLev %in% c(0.16, 0.32) ~ "Hard",
        TRUE ~ NA_character_
      ),
      effort = case_when(
        isStrength == 0 ~ "Low",
        isStrength == 1 ~ "High",
        TRUE ~ NA_character_
      ),
      condition = paste(difficulty, effort, sep = " / ")
    ) %>%
    filter(!is.na(difficulty), !is.na(effort))
  
  cat("Rows after filtering:", nrow(filtered_data), "\n")
  cat("Final rows with valid conditions:", nrow(filtered_data), "\n")
  cat("Condition breakdown:\n")
  print(table(filtered_data$condition))
  
  return(filtered_data)
}

# Function to create trial timeline
create_trial_timeline <- function(data, task_config) {
  cat("\n--- Creating Trial Timeline for", task_config$task_name, "---\n")
  
  # Find squeeze times (trial onsets)
  squeeze_times <- data %>%
    filter(duration_label == "Squeeze") %>%
    group_by(sub, trial_index) %>%
    summarise(squeeze_time = first(time), .groups = 'drop')
  
  cat("Found trial onsets (Squeeze) for", nrow(squeeze_times), "trials\n")
  
  # Join squeeze times back to main data
  data_with_timeline <- data %>%
    left_join(squeeze_times, by = c("sub", "trial_index")) %>%
    filter(!is.na(squeeze_time)) %>%
    mutate(
      time_from_squeeze = time - squeeze_time  # Time relative to squeeze onset in seconds
    )
  
  cat("Rows with timeline:", nrow(data_with_timeline), "\n")
  return(data_with_timeline)
}

# Function to calculate corrected B0 baseline
calculate_corrected_b0_baseline <- function(data, task_config) {
  cat("\n--- Calculating CORRECTED B0 Baseline (Pre-Anticipatory) ---\n")
  
  # Find pre-anticipatory fixation period relative to squeeze_time (time = 0)
  # MOVED TO [-1.0, -0.5]s to avoid anticipatory arousal peak
  b0_baseline <- data %>%
    filter(time_from_squeeze >= -1.0 & time_from_squeeze < -0.5) %>% # Earlier, more stable window
    group_by(sub, trial_index) %>%
    summarise(
      B0_mean = mean(pupil, na.rm = TRUE),
      B0_n = n(),
      .groups = 'drop'
    ) %>%
    filter(B0_n >= 10) # Require at least 10 samples for baseline
  
  cat("CORRECTED B0 baseline calculated for", nrow(b0_baseline), "trials\n")
  
  # Join back to main data
  data_with_b0 <- data %>%
    left_join(b0_baseline, by = c("sub", "trial_index")) %>%
    filter(!is.na(B0_mean)) %>%
    mutate(
      pupil_b0_pct = ifelse(B0_mean != 0 & !is.na(B0_mean), (pupil - B0_mean) / B0_mean * 100, NA_real_)
    )
  
  cat("Final data with corrected B0:", nrow(data_with_b0), "rows\n")
  
  return(data_with_b0)
}

# Function to calculate AUC for each trial
calculate_trial_aucs <- function(data, task_config) {
  cat("\n--- Calculating Trial-Level AUCs for", task_config$task_name, "---\n")
  
  # Define time windows based on specifications
  physical_start <- 1.5
  physical_end <- 3.5
  cognitive_start <- task_config$cognitive_window_start
  cognitive_end <- task_config$cognitive_window_end
  total_start <- 0.5
  total_end <- 5.5
  
  cat("Time windows defined:\n")
  cat("  Physical: ", physical_start, "to", physical_end, "seconds\n")
  cat("  Cognitive: ", cognitive_start, "to", cognitive_end, "seconds\n")
  cat("  Total: ", total_start, "to", total_end, "seconds\n")
  
  # Calculate AUC for each trial
  trial_aucs <- data %>%
    group_by(sub, trial_index, difficulty, effort, condition) %>%
    summarise(
      # Physical AUC
      AUC_Physical = if(sum(!is.na(pupil_b0_pct[time_from_squeeze >= physical_start & time_from_squeeze <= physical_end])) > 1) {
        trapz(time_from_squeeze[time_from_squeeze >= physical_start & time_from_squeeze <= physical_end],
              pupil_b0_pct[time_from_squeeze >= physical_start & time_from_squeeze <= physical_end])
      } else NA_real_,
      
      # Cognitive AUC
      AUC_Cognitive = if(sum(!is.na(pupil_b0_pct[time_from_squeeze >= cognitive_start & time_from_squeeze <= cognitive_end])) > 1) {
        trapz(time_from_squeeze[time_from_squeeze >= cognitive_start & time_from_squeeze <= cognitive_end],
              pupil_b0_pct[time_from_squeeze >= cognitive_start & time_from_squeeze <= cognitive_end])
      } else NA_real_,
      
      # Total AUC
      AUC_Total = if(sum(!is.na(pupil_b0_pct[time_from_squeeze >= total_start & time_from_squeeze <= total_end])) > 1) {
        trapz(time_from_squeeze[time_from_squeeze >= total_start & time_from_squeeze <= total_end],
              pupil_b0_pct[time_from_squeeze >= total_start & time_from_squeeze <= total_end])
      } else NA_real_,
      
      .groups = 'drop'
    ) %>%
    filter(!is.na(AUC_Physical) & !is.na(AUC_Cognitive) & !is.na(AUC_Total))
  
  cat("Trial-level AUCs calculated for", nrow(trial_aucs), "trials\n")
  
  return(trial_aucs)
}

# Function to run statistical models
run_auc_models <- function(data, task_name) {
  cat("\n--- Running AUC Statistical Models for", task_name, "---\n")
  
  # Convert factors for proper modeling
  data$difficulty <- factor(data$difficulty, levels = c("Easy", "Hard"))
  data$effort <- factor(data$effort, levels = c("Low", "High"))
  data$subject <- factor(data$subject)
  
  # Model 1: Physical Effort
  cat("\nModel 1: AUC_Physical ~ difficulty * effort + (1|subject)\n")
  model_physical <- lmer(AUC_Physical ~ difficulty * effort + (1|subject), data = data)
  print(summary(model_physical))
  
  # Model 2: Cognitive Effort
  cat("\nModel 2: AUC_Cognitive ~ difficulty * effort + (1|subject)\n")
  model_cognitive <- lmer(AUC_Cognitive ~ difficulty * effort + (1|subject), data = data)
  print(summary(model_cognitive))
  
  # Model 3: Total Effort
  cat("\nModel 3: AUC_Total ~ difficulty * effort + (1|subject)\n")
  model_total <- lmer(AUC_Total ~ difficulty * effort + (1|subject), data = data)
  print(summary(model_total))
  
  return(list(
    physical = model_physical,
    cognitive = model_cognitive,
    total = model_total
  ))
}

# Function to create AUC visualization plots
create_auc_plots <- function(data, task_name) {
  cat("\n--- Creating AUC Visualization Plots for", task_name, "---\n")
  
  # Calculate subject-level means for plotting
  plot_data <- data %>%
    group_by(subject, difficulty, effort, condition) %>%
    summarise(
      mean_AUC_Physical = mean(AUC_Physical, na.rm = TRUE),
      mean_AUC_Cognitive = mean(AUC_Cognitive, na.rm = TRUE),
      mean_AUC_Total = mean(AUC_Total, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    group_by(difficulty, effort, condition) %>%
    summarise(
      grand_mean_Physical = mean(mean_AUC_Physical, na.rm = TRUE),
      grand_mean_Cognitive = mean(mean_AUC_Cognitive, na.rm = TRUE),
      grand_mean_Total = mean(mean_AUC_Total, na.rm = TRUE),
      se_Physical = sd(mean_AUC_Physical, na.rm = TRUE) / sqrt(n()),
      se_Cognitive = sd(mean_AUC_Cognitive, na.rm = TRUE) / sqrt(n()),
      se_Total = sd(mean_AUC_Total, na.rm = TRUE) / sqrt(n()),
      .groups = 'drop'
    )
  
  # Define colors and line types for conditions (matching time-series plots)
  condition_colors <- c(
    "Easy / Low" = "#1f77b4",   # Blue
    "Easy / High" = "#ff7f0e",  # Orange  
    "Hard / Low" = "#2ca02c",   # Green
    "Hard / High" = "#d62728"   # Red
  )
  
  # Plot 1: AUC_Physical
  plot_physical <- ggplot(plot_data, aes(x = difficulty, y = grand_mean_Physical, 
                                         fill = condition, group = condition)) +
    geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
    geom_errorbar(aes(ymin = grand_mean_Physical - se_Physical, 
                      ymax = grand_mean_Physical + se_Physical),
                  position = position_dodge(0.9), width = 0.2) +
    scale_fill_manual(values = condition_colors) +
    labs(
      title = paste("Physical Effort AUC -", task_name),
      subtitle = "Area Under Curve (1.5-3.5s window)",
      x = "Task Difficulty",
      y = "AUC (Physical Effort)",
      fill = "Condition"
    ) +
    theme_minimal() +
    theme(
      text = element_text(size = 12),
      plot.title = element_text(size = 14, face = "bold"),
      legend.position = "bottom"
    )
  
  # Plot 2: AUC_Cognitive
  plot_cognitive <- ggplot(plot_data, aes(x = difficulty, y = grand_mean_Cognitive, 
                                          fill = condition, group = condition)) +
    geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
    geom_errorbar(aes(ymin = grand_mean_Cognitive - se_Cognitive, 
                      ymax = grand_mean_Cognitive + se_Cognitive),
                  position = position_dodge(0.9), width = 0.2) +
    scale_fill_manual(values = condition_colors) +
    labs(
      title = paste("Cognitive Effort AUC -", task_name),
      subtitle = "Area Under Curve (post-stimulus window)",
      x = "Task Difficulty",
      y = "AUC (Cognitive Effort)",
      fill = "Condition"
    ) +
    theme_minimal() +
    theme(
      text = element_text(size = 12),
      plot.title = element_text(size = 14, face = "bold"),
      legend.position = "bottom"
    )
  
  # Plot 3: AUC_Total
  plot_total <- ggplot(plot_data, aes(x = difficulty, y = grand_mean_Total, 
                                      fill = condition, group = condition)) +
    geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
    geom_errorbar(aes(ymin = grand_mean_Total - se_Total, 
                      ymax = grand_mean_Total + se_Total),
                  position = position_dodge(0.9), width = 0.2) +
    scale_fill_manual(values = condition_colors) +
    labs(
      title = paste("Total Effort AUC -", task_name),
      subtitle = "Area Under Curve (0.5-5.5s window)",
      x = "Task Difficulty",
      y = "AUC (Total Effort)",
      fill = "Condition"
    ) +
    theme_minimal() +
    theme(
      text = element_text(size = 12),
      plot.title = element_text(size = 14, face = "bold"),
      legend.position = "bottom"
    )
  
  # Combine plots
  combined_plots <- plot_physical / plot_cognitive / plot_total
  
  # Save individual plots
  ggsave(file.path(OUTPUT_DIR, paste0(task_name, "_AUC_Physical.png")), 
         plot_physical, width = 10, height = 6, dpi = 300)
  ggsave(file.path(OUTPUT_DIR, paste0(task_name, "_AUC_Cognitive.png")), 
         plot_cognitive, width = 10, height = 6, dpi = 300)
  ggsave(file.path(OUTPUT_DIR, paste0(task_name, "_AUC_Total.png")), 
         plot_total, width = 10, height = 6, dpi = 300)
  ggsave(file.path(OUTPUT_DIR, paste0(task_name, "_AUC_Combined.png")), 
         combined_plots, width = 10, height = 15, dpi = 300)
  
  cat("AUC plots saved for", task_name, "\n")
  
  return(list(
    physical = plot_physical,
    cognitive = plot_cognitive,
    total = plot_total,
    combined = combined_plots
  ))
}

# Main processing loop
cat("=== LCYA AUC Analysis: Physical and Cognitive Effort ===\n")
cat("Comprehensive pupillary response analysis using corrected baseline data\n\n")

all_auc_results <- list()
all_models <- list()

for (task_name in names(task_configs)) {
  cat(paste(rep("=", 60), collapse = ""), "\n")
  cat("PROCESSING TASK:", task_name, "\n")
  cat(paste(rep("=", 60), collapse = ""), "\n")
  
  # Step 1: Load data
  raw_data <- load_task_data(task_name)
  
  # Step 2: Create trial timeline
  timeline_data <- create_trial_timeline(raw_data, task_configs[[task_name]])
  
  # Step 3: Calculate corrected B0 baseline
  b0_data <- calculate_corrected_b0_baseline(timeline_data, task_configs[[task_name]])
  
  # Step 4: Calculate trial-level AUCs
  auc_data <- calculate_trial_aucs(b0_data, task_configs[[task_name]])
  
  # Add subject column for modeling (rename 'sub' to 'subject')
  auc_data$subject <- auc_data$sub
  
  # Step 5: Run statistical models
  models <- run_auc_models(auc_data, task_name)
  all_models[[task_name]] <- models
  
  # Step 6: Create visualization plots
  plots <- create_auc_plots(auc_data, task_name)
  all_auc_results[[task_name]] <- plots
  
  # Save AUC data for further analysis
  write.csv(auc_data, file.path(OUTPUT_DIR, paste0(task_name, "_AUC_Data.csv")), row.names = FALSE)
  
  cat("\n✅", task_name, "AUC analysis complete!\n")
}

# Create combined plots across all tasks
if (length(all_auc_results) > 0) {
  cat("\n--- Creating Cross-Task Combined AUC Plots ---\n")
  
  # This would require combining data across tasks - can be added if needed
  cat("Individual task AUC analyses completed successfully!\n")
}

cat("\n🎉 AUC analysis complete!\n")
cat("Check the PI_Feedback_Outputs directory for all AUC results and plots.\n")


