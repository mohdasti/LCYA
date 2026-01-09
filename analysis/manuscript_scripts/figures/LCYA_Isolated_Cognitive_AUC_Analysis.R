#!/usr/bin/env Rscript

# LCYA Isolated Cognitive AUC Analysis
# This script calculates a new Isolated_Cognitive_AUC measure,
# runs a statistical model, and generates visualizations based on PI feedback.

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(lme4) # For linear mixed-effects models
  library(lmerTest) # For p-values in lme4
  library(cowplot) # For combining plots
  library(patchwork) # For combining plots
})

# Set up directories
BASE_DIR <- "/Users/mohdasti/Documents/LC–YA"
DATA_DIR <- file.path(BASE_DIR, "100 Hz")
OUTPUT_DIR <- file.path(BASE_DIR, "PI_Feedback_Outputs") # Using existing output directory

# Ensure output directory exists
if (!dir.exists(OUTPUT_DIR)) {
  dir.create(OUTPUT_DIR, recursive = TRUE)
}

cat("=== LCYA Isolated Cognitive AUC Analysis ===\n")

# Define the common color scheme
condition_colors <- c(
  "Easy / Low" = "#5DADE2",    # Light blue
  "Easy / High" = "#2E86AB",   # Dark blue  
  "Hard / Low" = "#EC70AB",    # Light pink
  "Hard / High" = "#A23B72"    # Dark pink
)

timeline_bar_colors <- list(
  baseline = "#7F8C8D",
  total_auc = "#1F78B4",
  cognitive_auc = "#D95F02"
)

# Task configurations (s2_probe_onset and response_onset will be updated dynamically)
task_configs <- list(
  CDT = list(
    task_name = "CDT",
    target_stimulus = "Arrow", # Keep for now to maintain previous functionality
    s2_probe_label = "Arrow",
    response_label = "Response",
    confidence_label = "Confidence",
    s2_probe_onset_median = 4.39, # Median Arrow onset for plotting
    response_onset_median = 6.08,  # Median Response onset for plotting
    confidence_onset_median = 8.07, # Median Confidence onset for plotting
    total_auc_start = 0, # From squeeze onset
    b2b_duration = 0.5, # Duration of local baseline before S2/Probe onset
    cognitive_auc_latency = 0.3, # Latency after S2/Probe onset for cognitive AUC start
    cognitive_auc_duration = 1.5, # Duration of cognitive AUC after latency
    stimulus_marker_label = "Array onset", # Updated per advisor: Arrow renamed to Array
    stimulus_marker_short = "Array onset",
    response_marker_label = "Probe + Response" # Updated per advisor: Response renamed for CDT
  ),
  ADT = list(
    task_name = "ADT",
    target_stimulus = "Stimulus", # Keep for now to maintain previous functionality
    s2_probe_label = "Stimulus", 
    response_label = "Response",
    confidence_label = "Confidence",
    s2_probe_onset_median = 3.78, # Median Stimulus onset for plotting
    response_onset_median = 5.49,  # Median Response onset for plotting
    confidence_onset_median = 6.02, # Median Confidence onset for plotting
    total_auc_start = 0, # From squeeze onset
    b2b_duration = 0.5,
    cognitive_auc_latency = 0.3,
    cognitive_auc_duration = 1.5,
    stimulus_marker_label = "Target onset",
    stimulus_marker_short = "Target onset",
    response_marker_label = "Response" # Keep original for ADT
  ),
  VDT = list(
    task_name = "VDT",
    target_stimulus = "Stimulus", # Keep for now to maintain previous functionality
    s2_probe_label = "Stimulus", 
    response_label = "Response",
    confidence_label = "Confidence",
    s2_probe_onset_median = 3.78, # Median Stimulus onset for plotting
    response_onset_median = 5.49,  # Median Response onset for plotting
    confidence_onset_median = 6.01, # Median Confidence onset for plotting
    total_auc_start = 0, # From squeeze onset
    b2b_duration = 0.5,
    cognitive_auc_latency = 0.3,
    cognitive_auc_duration = 1.5,
    stimulus_marker_label = "Target onset",
    stimulus_marker_short = "Target onset",
    response_marker_label = "Response" # Keep original for VDT
  )
)

# Function to load and preprocess data
load_task_data <- function(task_name) {
  cat("\n=== Loading", task_name, "Data ===\n")

  task_files <- list.files(DATA_DIR, pattern = paste0(".*", task_name, "_DS100_merged\\.csv$"), full.names = TRUE)
  all_data <- map_dfr(task_files, function(file_path) {
    data <- read_csv(file_path, show_col_types = FALSE)
    data$task_name <- task_name
    return(data)
  })

  # Filter and create conditions
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

  return(filtered_data)
}

# Function to create trial timeline
create_trial_timeline <- function(data, task_config) {
  cat("\n--- Creating Trial Timeline for", task_config$task_name, "---\n")

  squeeze_times <- data %>%
    filter(duration_label == "Squeeze") %>%
    group_by(sub, trial_index) %>%
    summarise(squeeze_time = first(time), .groups = 'drop')

  data_with_timeline <- data %>%
    left_join(squeeze_times, by = c("sub", "trial_index")) %>%
    filter(!is.na(squeeze_time)) %>%
    mutate(
      time_from_squeeze = time - squeeze_time
    )

  return(data_with_timeline)
}

# Function to get trial-specific event onsets
get_trial_event_onsets <- function(data, config) {
  cat("\n--- Getting Trial-Specific Event Onsets for", config$task_name, "---\n")
  
  squeeze_times <- data %>%
    filter(duration_label == "Squeeze") %>%
    group_by(sub, trial_index) %>%
    summarise(squeeze_time = first(time), .groups = 'drop')
  
  event_onsets <- data %>%
    filter(duration_label %in% c("Squeeze", config$s2_probe_label, config$response_label, config$confidence_label)) %>%
    group_by(sub, trial_index, duration_label) %>%
    summarise(event_time = first(time), .groups = 'drop') %>%
    pivot_wider(names_from = duration_label, values_from = event_time, names_prefix = "onset_")
  
  full_event_data <- squeeze_times %>%
    left_join(event_onsets, by = c("sub", "trial_index")) %>%
    mutate(
      s2_probe_onset = .data[[paste0("onset_", config$s2_probe_label)]] - squeeze_time,
      response_onset = onset_Response - squeeze_time,
      confidence_onset = onset_Confidence - squeeze_time
    ) %>% # Select only relevant columns before returning
    select(sub, trial_index, squeeze_time, s2_probe_onset, response_onset, confidence_onset)
  
  # Fill NA values with median from task_configs for plotting if needed
  full_event_data <- full_event_data %>%
    mutate(
      s2_probe_onset = ifelse(is.na(s2_probe_onset), config$s2_probe_onset_median, s2_probe_onset),
      response_onset = ifelse(is.na(response_onset), config$response_onset_median, response_onset),
      confidence_onset = ifelse(is.na(confidence_onset), config$confidence_onset_median, confidence_onset)
    )
  
  return(full_event_data)
}

# Function to calculate local baseline (B2b) and create isolated pupil trace
calculate_isolated_pupil_trace <- function(data, config, trial_event_onsets) {
  cat("\n--- Calculating Local Baseline (B2b) and Isolated Pupil Trace for", config$task_name, "---\n")

  # Merge trial-specific event onsets
  data_with_onsets <- data %>%
    left_join(trial_event_onsets, by = c("sub", "trial_index", "squeeze_time"))

  data_processed <- data_with_onsets %>%
    group_by(sub, trial_index) %>%
    mutate(
      b2b_start = s2_probe_onset - config$b2b_duration,
      b2b_end = s2_probe_onset,
      
      # Step 2: Calculate the Local Baseline (B2b) for Each Trial
      local_baseline_b2b = mean(pupil[time_from_squeeze >= b2b_start & 
                                     time_from_squeeze < b2b_end], na.rm = TRUE),
      
      # Step 2b: Calculate global baseline (B0) - 500ms window from -0.5s to 0s before squeeze onset  
      global_baseline_b0 = mean(pupil[time_from_squeeze >= -0.5 & time_from_squeeze < 0], na.rm = TRUE),
      
      # Step 3: Create Isolated Pupil Trace
      # Apply global baseline correction throughout to converge all conditions at squeeze onset (time = 0)
      pupil_isolated = pupil - global_baseline_b0
    ) %>% 
    ungroup()

  return(data_processed)
}

# Function to calculate Area Under the Curve (AUC) using trapezoidal rule
calculate_auc <- function(time_series, data_series, start_time, end_time) {
  # Filter data for the specified window
  # Ensure time_series and data_series are numeric and of equal length
  # Filter out NA values from data_series as it would invalidate AUC for that trial.
  valid_indices <- !is.na(data_series) & (time_series >= start_time & time_series <= end_time)
  
  if (sum(valid_indices) < 2) { # Need at least 2 points for trapezoidal rule
    return(NA_real_)
  }
  
  t <- time_series[valid_indices]
  y <- data_series[valid_indices]
  
  # Sort by time to ensure correct trapezoidal calculation
  order_idx <- order(t)
  t <- t[order_idx]
  y <- y[order_idx]
  
  # Calculate AUC using trapezoidal rule
  auc_val <- sum(0.5 * (y[-length(y)] + y[-1]) * diff(t), na.rm = TRUE)
  return(auc_val)
}


# Main processing loop
all_processed_data <- list()
all_cognitive_auc_data <- list()
all_total_auc_data <- list()

for (task_name in names(task_configs)) {
  cat(paste(rep("=", 60), collapse = ""), "\n")
  cat("PROCESSING TASK:", task_name, "\n")
  cat(paste(rep("=", 60), collapse = ""), "\n")

  config <- task_configs[[task_name]] # Define config for the current task

  # Load data
  raw_data <- load_task_data(task_name)

  # Create trial timeline
  timeline_data <- create_trial_timeline(raw_data, config)

  # Get trial-specific event onsets
  trial_event_onsets <- get_trial_event_onsets(raw_data, config)

  # Calculate local baseline and isolated pupil trace (Step 1, 2, 3)
  isolated_data <- calculate_isolated_pupil_trace(timeline_data, config, trial_event_onsets)
  all_processed_data[[task_name]] <- isolated_data

  # Step 4: Calculate Cognitive_AUC (refined) - using trial-specific response_onset
  cognitive_auc_data <- isolated_data %>%
    mutate(
      cognitive_auc_start_trial = s2_probe_onset + config$cognitive_auc_latency,
      cognitive_auc_end_trial = response_onset # Trial-specific response onset
    ) %>%
    group_by(sub, trial_index, task_name, difficulty, effort, condition) %>%
    summarise(
      Cognitive_AUC = calculate_auc(time_from_squeeze, pupil_isolated,
                                           cognitive_auc_start_trial,
                                           cognitive_auc_end_trial),
      .groups = 'drop'
    )
  all_cognitive_auc_data[[task_name]] <- cognitive_auc_data
  cat("✅ Cognitive_AUC calculated for", task_name, "\n")

  # Calculate Total_AUC (Lani's request) - using trial-specific response_onset
  total_auc_data <- timeline_data %>%
    left_join(trial_event_onsets, by = c("sub", "trial_index", "squeeze_time")) %>%
    mutate(
      total_auc_start_trial = config$total_auc_start,
      total_auc_end_trial = response_onset # Trial-specific response onset
    ) %>%
    group_by(sub, trial_index, task_name, difficulty, effort, condition) %>%
    summarise(
      Total_AUC = calculate_auc(time_from_squeeze, pupil,
                                     total_auc_start_trial,
                                     total_auc_end_trial),
      .groups = 'drop'
    )
  all_total_auc_data[[task_name]] <- total_auc_data
  cat("✅ Total_AUC calculated for", task_name, "\n")
}

# Combine all AUC data
combined_cognitive_auc_data <- bind_rows(all_cognitive_auc_data)
combined_total_auc_data <- bind_rows(all_total_auc_data)

# Step 5: Run the New Statistical Model for Cognitive_AUC
cat("\n=== Running Statistical Model for Cognitive_AUC (Refined) ===\n")

# Aggregate to subject-level
subject_cognitive_auc_data <- combined_cognitive_auc_data %>%
  group_by(sub, task_name, difficulty, effort, condition) %>%
  summarise(mean_Cognitive_AUC = mean(Cognitive_AUC, na.rm = TRUE), .groups = 'drop')

# Convert to factor for LMM
subject_cognitive_auc_data$difficulty <- as.factor(subject_cognitive_auc_data$difficulty)
subject_cognitive_auc_data$effort <- as.factor(subject_cognitive_auc_data$effort)
subject_cognitive_auc_data$sub <- as.factor(subject_cognitive_auc_data$sub)

# Run LME model for each task (Lani's recommendations: ADT & VDT only for Cognitive AUC)
cognitive_model_summaries <- list()
for (task in unique(subject_cognitive_auc_data$task_name)) {
  cat("\n--- Cognitive_AUC Model for Task:", task, "---\n")
  task_data <- filter(subject_cognitive_auc_data, task_name == task)
  
  # Lani's recommendation: Skip Cognitive AUC analysis for CDT
  if (task == "CDT") {
    cat("Skipping Cognitive_AUC analysis for CDT per Lani's recommendations (cognitive effort effects uninterpretable)\n")
    next
  }
  
  if (n_distinct(task_data$sub) > 1 && nrow(task_data) > 0) {
    model <- lmer(mean_Cognitive_AUC ~ difficulty * effort + (1|sub), data = task_data)
    cognitive_model_summaries[[task]] <- summary(model)
    print(summary(model))
  } else {
    cat("Not enough data/subjects for Cognitive_AUC LMM for task", task, ". Skipping LMM for this task.\n")
    if (nrow(task_data) > 0) {
      model <- lm(mean_Cognitive_AUC ~ difficulty * effort, data = task_data)
      cognitive_model_summaries[[task]] <- summary(model)
      print(summary(model))
    }
  }
}

# Save Cognitive_AUC model summaries
cognitive_model_output_file <- file.path(OUTPUT_DIR, "Cognitive_AUC_LMM_Summaries_Refined.txt")
walk2(names(cognitive_model_summaries), cognitive_model_summaries, ~ capture.output(print(.y), file = cognitive_model_output_file, append = TRUE, sep = "\n"))
cat("✅ Refined Cognitive_AUC model summaries saved to:", cognitive_model_output_file, "\n")

# New: Step 5 for Total_AUC
cat("\n=== Running Statistical Model for Total_AUC (Lani's Request) ===\n")

# Aggregate to subject-level
subject_total_auc_data <- combined_total_auc_data %>%
  group_by(sub, task_name, difficulty, effort, condition) %>%
  summarise(mean_Total_AUC = mean(Total_AUC, na.rm = TRUE), .groups = 'drop')

# Convert to factor for LMM
subject_total_auc_data$difficulty <- as.factor(subject_total_auc_data$difficulty)
subject_total_auc_data$effort <- as.factor(subject_total_auc_data$effort)
subject_total_auc_data$sub <- as.factor(subject_total_auc_data$sub)

# Run LME model for each task (Lani's recommendations: CDT = effort only, ADT & VDT = difficulty * effort)
total_model_summaries <- list()
for (task in unique(subject_total_auc_data$task_name)) {
  cat("\n--- Total_AUC Model for Task:", task, "---\n")
  task_data <- filter(subject_total_auc_data, task_name == task)
  
  if (n_distinct(task_data$sub) > 1 && nrow(task_data) > 0) {
    # Lani's recommendation: CDT uses effort only (no difficulty or interaction)
    if (task == "CDT") {
      cat("Using effort-only model for CDT per Lani's recommendations (cognitive effort effects uninterpretable)\n")
      model <- lmer(mean_Total_AUC ~ effort + (1|sub), data = task_data)
    } else {
      # ADT & VDT: Full 2x2 ANOVA (difficulty * effort)
      model <- lmer(mean_Total_AUC ~ difficulty * effort + (1|sub), data = task_data)
    }
    total_model_summaries[[task]] <- summary(model)
    print(summary(model))
  } else {
    cat("Not enough data/subjects for Total_AUC LMM for task", task, ". Skipping LMM for this task.\n")
    if (nrow(task_data) > 0) {
      # Same logic for fallback LM models
      if (task == "CDT") {
        model <- lm(mean_Total_AUC ~ effort, data = task_data)
      } else {
        model <- lm(mean_Total_AUC ~ difficulty * effort, data = task_data)
      }
      total_model_summaries[[task]] <- summary(model)
      print(summary(model))
    }
  }
}

# Save Total_AUC model summaries
total_model_output_file <- file.path(OUTPUT_DIR, "Total_AUC_LMM_Summaries_Lani_Request.txt")
walk2(names(total_model_summaries), total_model_summaries, ~ capture.output(print(.y), file = total_model_output_file, append = TRUE, sep = "\n"))
cat("✅ Total_AUC model summaries saved to:", total_model_output_file, "\n")


# Step 6: Visualize the New Results
cat("\n=== Generating Visualizations for Cognitive_AUC and Total_AUC ===\n")

# 6.1 Bar plot for mean Cognitive_AUC (Refined)
plot_cognitive_bar <- ggplot(subject_cognitive_auc_data, aes(x = condition, y = mean_Cognitive_AUC, fill = condition)) +
  geom_bar(stat = "summary", fun = "mean", position = position_dodge(width = 0.9), color = "black") +
  stat_summary(fun.data = "mean_se", geom = "errorbar", width = 0.2, position = position_dodge(width = 0.9)) +
  facet_wrap(~task_name, scales = "free_y") +
  labs(
    title = "Mean Cognitive AUC (Refined) by Condition and Task",
    x = "Condition",
    y = "Mean Cognitive AUC",
    fill = "Condition"
  ) +
  scale_fill_manual(values = condition_colors) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

cognitive_auc_bar_plot_file <- file.path(OUTPUT_DIR, "Cognitive_AUC_Bar_Plot_Refined.png")
ggsave(cognitive_auc_bar_plot_file, plot_cognitive_bar, width = 10, height = 7, dpi = 300)
cat("✅ Refined Cognitive_AUC bar plot saved to:", cognitive_auc_bar_plot_file, "\n")

# New: 6.1 Bar plot for mean Total_AUC (Lani's Request)
plot_total_bar <- ggplot(subject_total_auc_data, aes(x = condition, y = mean_Total_AUC, fill = condition)) +
  geom_bar(stat = "summary", fun = "mean", position = position_dodge(width = 0.9), color = "black") +
  stat_summary(fun.data = "mean_se", geom = "errorbar", width = 0.2, position = position_dodge(width = 0.9)) +
  facet_wrap(~task_name, scales = "free_y") +
  labs(
    title = "Mean Total AUC (Lani's Request) by Condition and Task",
    x = "Condition",
    y = "Mean Total AUC",
    fill = "Condition"
  ) +
  scale_fill_manual(values = condition_colors) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

total_auc_bar_plot_file <- file.path(OUTPUT_DIR, "Total_AUC_Bar_Plot_Lani_Request.png")
ggsave(total_auc_bar_plot_file, plot_total_bar, width = 10, height = 7, dpi = 300)
cat("✅ Total_AUC bar plot (Lani's Request) saved to:", total_auc_bar_plot_file, "\n")

# 6.2 Event-locked waveform plots for pupil_isolated trace (still relevant for Cognitive AUC)
cat("\n--- Generating Isolated Pupil Waveform Plots (for Cognitive_AUC) ---\n")

all_waveform_plots <- list()
for (task_name in names(task_configs)) {
  task_data <- all_processed_data[[task_name]]
  config <- task_configs[[task_name]]
  
  # Create condition-specific averages for pupil_isolated (baseline-corrected pupil)
  waveform_summary <- task_data %>%
    group_by(condition, time_from_squeeze) %>%
    summarise(
      mean_pupil_isolated = mean(pupil_isolated, na.rm = TRUE),
      se_pupil_isolated = sd(pupil_isolated, na.rm = TRUE) / sqrt(n()),
      .groups = 'drop'
    ) %>% 
    filter(!is.na(mean_pupil_isolated))
  
  # Determine dynamic y-limits from smoothed means (MOVED HERE)
  x_range <- c(-0.5, config$response_onset_median)
  smoothed_df <- suppressWarnings(
    ggplot_build(
      ggplot(waveform_summary, aes(x = time_from_squeeze, y = mean_pupil_isolated, color = condition)) +
        geom_smooth(se = TRUE, method = "gam", formula = y ~ s(x, k = 30))
    )$data[[1]] %>% as_tibble()
  )
  y_limits <- if (!is.null(smoothed_df) && nrow(smoothed_df) > 0) {
    # Use wider range (0.01 to 0.99) to ensure confidence ribbons are fully visible
    y_min <- quantile(smoothed_df$y[smoothed_df$x >= x_range[1] & smoothed_df$x <= x_range[2]], 0.01, na.rm = TRUE)
    y_max <- quantile(smoothed_df$y[smoothed_df$x >= x_range[1] & smoothed_df$x <= x_range[2]], 0.99, na.rm = TRUE)
    c(y_min, y_max)
  } else c(NA_real_, NA_real_)

  if (any(!is.finite(y_limits))) {
    y_limits <- range(waveform_summary$mean_pupil_isolated, na.rm = TRUE)
  }
  if (any(!is.finite(y_limits)) || diff(y_limits) == 0) {
    fallback_span <- max(abs(y_limits), na.rm = TRUE)
    if (!is.finite(fallback_span) || fallback_span == 0) {
      fallback_span <- 1
    }
    y_limits <- c(-fallback_span, fallback_span)
  }

  cat("Dynamic y-limits for", task_name, ":", round(y_limits[1], 3), "to", round(y_limits[2], 3), "\n")

  # Retrieve trial-specific event onsets for plotting (using medians for consistent markers)
  # NOTE: The actual AUC calculations use trial-specific onsets, but for plotting markers,
  # medians are often used to represent typical event timing across trials.
  s2_probe_onset_plot <- config$s2_probe_onset_median
  response_onset_plot <- config$response_onset_median
  cognitive_start_plot <- s2_probe_onset_plot + config$cognitive_auc_latency
  if (cognitive_start_plot > response_onset_plot) {
    cognitive_start_plot <- response_onset_plot
  }

  y_range_span <- diff(y_limits)
  if (!is.finite(y_range_span) || y_range_span <= 0) {
    y_range_span <- max(abs(y_limits), na.rm = TRUE)
    if (!is.finite(y_range_span) || y_range_span == 0) {
      y_range_span <- 1
    }
  }
  extra_margin <- y_range_span * 0.3
  # Increase bottom margin to ensure Pre-trial Baseline bar and text have enough space
  y_lower_limit <- y_limits[1] - extra_margin * 2.0
  y_upper_limit <- y_limits[2]

  baseline_label_text <- "Pre-trial Baseline"
  total_label_text <- "Total AUC"
  cognitive_label_text <- "Cognitive AUC"
  pre_stimulus_baseline_label_text <- "Pre-stimulus Baseline"
  
  # Calculate pre-stimulus baseline period (B2b) for ADT and VDT
  pre_stimulus_baseline_start <- s2_probe_onset_plot - config$b2b_duration
  pre_stimulus_baseline_end <- s2_probe_onset_plot
  
  # Build bar positions conditionally based on task
  if (task_name == "CDT") {
    # CDT: Only Pre-trial Baseline and Total AUC (no Cognitive AUC or Pre-stimulus Baseline)
    bar_positions <- tibble::tibble(
      label = c(baseline_label_text, total_label_text),
      xstart = c(-0.5, 0),
      xend = c(0, response_onset_plot),
      color = c(
        timeline_bar_colors$baseline,
        timeline_bar_colors$total_auc
      )
    )
  } else {
    # ADT and VDT: Pre-trial Baseline, Total AUC, Pre-stimulus Baseline, and Cognitive AUC
    bar_positions <- tibble::tibble(
      label = c(baseline_label_text, total_label_text, pre_stimulus_baseline_label_text, cognitive_label_text),
      xstart = c(-0.5, 0, pre_stimulus_baseline_start, cognitive_start_plot),
      xend = c(0, response_onset_plot, pre_stimulus_baseline_end, response_onset_plot),
      color = c(
        timeline_bar_colors$baseline,
        timeline_bar_colors$total_auc,
        timeline_bar_colors$baseline,  # Pre-stimulus baseline also grey
        timeline_bar_colors$cognitive_auc
      )
    )
  }

  bar_spacing <- extra_margin / (nrow(bar_positions) + 1)
  # Adjust text offset: CDT uses smaller offset (looks nice), ADT/VDT need larger offset for better spacing
  text_offset_multiplier <- if (task_name == "CDT") 0.65 else 1.2
  bar_positions <- bar_positions %>%
    mutate(
      y = y_lower_limit + bar_spacing * seq_len(n()),
      text_y = y + bar_spacing * text_offset_multiplier,
      x_label = (xstart + xend) / 2
    )

  # Create event markers - use task-specific labels
  event_markers_plot <- tibble::tibble(
    event = c("Trial onset", config$stimulus_marker_label, config$response_marker_label),
    time = c(0, s2_probe_onset_plot, response_onset_plot)
  ) %>%
    filter(!is.na(time)) %>%
    # Adjust x-position for response marker to shift label leftward (so it doesn't go over plot border)
    mutate(
      label_x = if_else(event == config$response_marker_label, 
                       time - 0.15,  # Shift response marker label 0.15 seconds left
                       time),
      hjust_val = if_else(event == config$response_marker_label,
                         1.0,  # Right-align the response marker (text extends left from this point)
                         0.5)  # Center-align other markers
    )

  # Position event labels - use fixed y=5 for CDT, calculated position for others
  event_label_y <- if (task_name == "CDT") {
    5  # Fixed y-position at 5 for CDT labels
  } else {
    y_upper_limit - y_range_span * 0.005  # Standard position for ADT and VDT (slightly below top)
  }
  
  # Adjust y-axis upper limit to accommodate fixed y=5 labels for CDT
  y_upper_limit_adjusted <- if (task_name == "CDT") {
    max(y_upper_limit, 5 + y_range_span * 0.02)  # Ensure y=5 labels are visible, with small margin
  } else {
    y_upper_limit
  }
  
  # Adjust vjust for CDT to position text correctly (vjust=1 means text is above the point)
  event_label_vjust <- if (task_name == "CDT") {
    0.9  # Position text slightly above for CDT
  } else {
    1.1  # Standard for ADT and VDT
  }

  # Plotting range - adjusting to show baseline period and end at response onset  
  # Start from -0.5 seconds (baseline period) and end at response onset
  plot_start_time <- -0.5  # Show the baseline period before squeeze onset
  plot_end_time <- response_onset_plot  # End at Response onset
  
  plot_waveform <- ggplot(waveform_summary, aes(x = time_from_squeeze, y = mean_pupil_isolated, color = condition)) +
    # Use geom_smooth for smoothed lines with confidence intervals
    geom_smooth(aes(fill = condition), method = "gam", formula = y ~ s(x, k = 30), linewidth = 1.2, span = 0.2, se = TRUE) +
    
    # Add vertical markers for all events (Trial onset, Stimulus, Response)
    {if (nrow(event_markers_plot) > 0) geom_vline(data = event_markers_plot, aes(xintercept = time), linetype = "dashed", color = "grey40", linewidth = 0.6) } +
    {if (nrow(event_markers_plot) > 0) geom_text(data = event_markers_plot, aes(x = label_x, y = event_label_y, label = event, hjust = hjust_val), inherit.aes = FALSE, size = 4.5, color = "grey20", vjust = event_label_vjust, fontface = "bold") } +

    # Annotate baseline and AUC windows with horizontal bars
    geom_segment(
      data = bar_positions,
      aes(x = xstart, xend = xend, y = y, yend = y, color = I(color)),
      inherit.aes = FALSE,
      linewidth = 2.2,
      lineend = "round"
    ) +
    geom_text(
      data = bar_positions,
      aes(x = x_label, y = text_y, label = label, color = I(color)),
      inherit.aes = FALSE,
      size = 3.5,
      fontface = "bold"
    ) +

  labs(
    title = task_name,
    x = if (task_name == "VDT") "Time Relative to Squeeze Onset (seconds)" else NULL,
    y = "Isolated Pupil (arbitrary units)",
    color = "Condition",
    fill = "Condition"
  ) +
    scale_color_manual(values = condition_colors) +
    scale_fill_manual(values = condition_colors) + # Apply new color scheme
    scale_x_continuous(breaks = seq(0, 5, by = 1)) +
    coord_cartesian(xlim = c(plot_start_time, plot_end_time), ylim = c(y_lower_limit, y_upper_limit_adjusted)) +
    theme_minimal() +
    theme(
      text = element_text(size = 12),
      plot.title = element_text(size = 18, face = "bold"),
      axis.title = element_text(size = 14, face = "bold"),
      axis.text = element_text(size = 12),
      legend.position = "bottom",
      legend.box = "horizontal",
      legend.title = element_text(size = 14, face = "bold"),
      legend.text = element_text(size = 12),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "grey90", linewidth = 0.3),
      plot.margin = margin(12, 20, 32, 16)
    )
  
  all_waveform_plots[[task_name]] <- plot_waveform
}

# Combine waveform plots
combined_waveform_plot <- (all_waveform_plots[["CDT"]] / all_waveform_plots[["ADT"]] / all_waveform_plots[["VDT"]]) +
  plot_layout(guides = "collect") &
  theme(
    legend.position = "bottom",
    legend.direction = "horizontal",
    panel.spacing = grid::unit(2.4, "lines")
  )

waveform_output_file <- file.path(OUTPUT_DIR, "Cognitive_Pupil_Waveforms_Publication_Ready_v2.png") # Publication-ready 500ms baseline version (updated)
ggsave(waveform_output_file, combined_waveform_plot, width = 12, height = 15, dpi = 300)
cat("✅ Refined Cognitive Pupil waveform plots saved to:", waveform_output_file, "\n")

# Also save to publication directory
publication_dir <- file.path(BASE_DIR, "LCYA", "figures", "publication")
if (dir.exists(publication_dir)) {
  publication_output_file <- file.path(publication_dir, "Figure3_Pupil_Waveforms.png")
  ggsave(publication_output_file, combined_waveform_plot, width = 12, height = 15, dpi = 300)
  cat("✅ Figure 3 saved to publication directory:", publication_output_file, "\n")
} else {
  cat("⚠️  Publication directory not found:", publication_dir, "\n")
}

cat("\n🎉 Combined analysis complete! Check the PI_Feedback_Outputs directory for model summaries and plots.\n")
