#!/usr/bin/env Rscript

# Script to generate updated combined bar plots for Total AUC and Cognitive AUC
# Based on the refined analyses from LCYA_Isolated_Cognitive_AUC_Analysis.R
# Arranged in a 2x3 grid (AUC type as rows, tasks as columns)
# With unified legends and axis labels.

suppressPackageStartupMessages({
  library(tidyverse)
  library(patchwork)
})

# Set up directories
BASE_DIR <- "/Users/mohdasti/Documents/LC–YA"
DATA_DIR <- file.path(BASE_DIR, "100 Hz")
PLOTS_DIR <- file.path(BASE_DIR, "Complete_Manuscript_Plots", "Pupillary_Response_AUC_Plots")

# Create plots directory if it doesn't exist
if (!dir.exists(PLOTS_DIR)) {
  dir.create(PLOTS_DIR, recursive = TRUE)
}

# --- Data Loading and Preprocessing ---
# Re-using functions from LCYA_Isolated_Cognitive_AUC_Analysis.R

task_configs <- list(
  CDT = list(
    task_name = "CDT",
    target_stimulus = "Arrow",
    s2_probe_label = "Arrow",
    response_label = "Response",
    confidence_label = "Confidence"
  ),
  ADT = list(
    task_name = "ADT",
    target_stimulus = "Stimulus",
    s2_probe_label = "Stimulus", 
    response_label = "Response",
    confidence_label = "Confidence"
  ),
  VDT = list(
    task_name = "VDT",
    target_stimulus = "Stimulus",
    s2_probe_label = "Stimulus", 
    response_label = "Response",
    confidence_label = "Confidence"
  )
)

load_task_data <- function(task_name) {
  task_files <- list.files(DATA_DIR, pattern = paste0(".*", task_name, "_DS100_merged\\.csv$"), full.names = TRUE)
  all_data <- map_dfr(task_files, function(file_path) {
    data <- read_csv(file_path, show_col_types = FALSE)
    data$task_name <- task_name
    return(data)
  })

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

create_trial_timeline <- function(data, task_config) {
  squeeze_times <- data %>%
    filter(duration_label == "Squeeze") %>%
    group_by(sub, trial_index) %>%
    summarise(squeeze_time = first(time), .groups = 'drop')
  data_with_timeline <- data %>%
    left_join(squeeze_times, by = c("sub", "trial_index")) %>%
    filter(!is.na(squeeze_time)) %>%
    mutate(time_from_squeeze = time - squeeze_time)
  return(data_with_timeline)
}

get_trial_event_onsets <- function(data, config) {
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
    ) %>%
    select(sub, trial_index, squeeze_time, s2_probe_onset, response_onset, confidence_onset)
  return(full_event_data)
}

calculate_isolated_pupil_trace <- function(data, config, trial_event_onsets) {
  data_with_onsets <- data %>%
    left_join(trial_event_onsets, by = c("sub", "trial_index", "squeeze_time"))
  data_processed <- data_with_onsets %>%
    group_by(sub, trial_index) %>%
    mutate(
      b2b_start = s2_probe_onset - 0.5,
      b2b_end = s2_probe_onset,
      local_baseline_b2b = mean(pupil[time_from_squeeze >= b2b_start & time_from_squeeze < b2b_end], na.rm = TRUE),
      pupil_isolated = if_else(time_from_squeeze >= b2b_end, pupil - local_baseline_b2b, NA_real_)
    ) %>%
    ungroup()
  return(data_processed)
}

calculate_auc <- function(time_series, data_series, start_time, end_time) {
  valid_indices <- !is.na(data_series) & (time_series >= start_time & time_series <= end_time)
  if (sum(valid_indices) < 2) { return(NA_real_) }
  t <- time_series[valid_indices]
  y <- data_series[valid_indices]
  order_idx <- order(t)
  t <- t[order_idx]
  y <- y[order_idx]
  auc_val <- sum(0.5 * (y[-length(y)] + y[-1]) * diff(t), na.rm = TRUE)
  return(auc_val)
}

# --- Generate the data ---
all_cognitive_auc_data <- list()
all_total_auc_data <- list()

for (task_name in names(task_configs)) {
  config <- task_configs[[task_name]]
  raw_data <- load_task_data(task_name)
  timeline_data <- create_trial_timeline(raw_data, config)
  trial_event_onsets <- get_trial_event_onsets(raw_data, config)
  isolated_data <- calculate_isolated_pupil_trace(timeline_data, config, trial_event_onsets)

  cognitive_auc_data <- isolated_data %>%
    mutate(
      cognitive_auc_start_trial = s2_probe_onset + 0.3,
      cognitive_auc_end_trial = response_onset
    ) %>%
    group_by(sub, trial_index, task_name, difficulty, effort, condition) %>%
    summarise(
      Cognitive_AUC = calculate_auc(time_from_squeeze, pupil_isolated, first(cognitive_auc_start_trial), first(cognitive_auc_end_trial)),
      .groups = 'drop'
    )
  all_cognitive_auc_data[[task_name]] <- cognitive_auc_data

  total_auc_data <- timeline_data %>%
    left_join(trial_event_onsets, by = c("sub", "trial_index", "squeeze_time")) %>%
    group_by(sub, trial_index, task_name, difficulty, effort, condition) %>%
    summarise(
      Total_AUC = calculate_auc(time_from_squeeze, pupil, 0, first(response_onset)),
      .groups = 'drop'
    )
  all_total_auc_data[[task_name]] <- total_auc_data
}

subject_cognitive_auc_data <- bind_rows(all_cognitive_auc_data) %>%
  group_by(sub, task_name, difficulty, effort, condition) %>%
  summarise(mean_cognitive_auc = mean(Cognitive_AUC, na.rm = TRUE), .groups = 'drop')

subject_total_auc_data <- bind_rows(all_total_auc_data) %>%
  group_by(sub, task_name, difficulty, effort, condition) %>%
  summarise(mean_total_auc = mean(Total_AUC, na.rm = TRUE), .groups = 'drop')

# Combine into a single data frame for plotting
combined_auc_data <- subject_cognitive_auc_data %>%
  full_join(subject_total_auc_data, by = c("sub", "task_name", "difficulty", "effort", "condition")) %>%
  mutate(
    condition = factor(condition, levels = c("Easy / Low", "Easy / High", "Hard / Low", "Hard / High")),
    task_name = factor(task_name, levels = c("CDT", "ADT", "VDT"))
  )

# --- Plotting Logic (Adapted from LCYA_Combined_Dual_AUC_Plots.R) ---

condition_colors <- c(
  "Easy / Low" = "#5DADE2",
  "Easy / High" = "#2E86AB",
  "Hard / Low" = "#EC70AB",
  "Hard / High" = "#A23B72"
)

theme_publication <- function() {
  theme_minimal(base_size = 12) +
    theme(
      text = element_text(family = "Helvetica", color = "black"),
      plot.title = element_text(face = "bold", hjust = 0.5, size = 14),
      plot.subtitle = element_text(hjust = 0.5, size = 12, color = "gray30"),
      axis.title = element_text(face = "bold", size = 12),
      axis.text = element_text(size = 10, color = "black"),
      legend.title = element_text(face = "bold", size = 11),
      legend.text = element_text(size = 10),
      panel.grid.major = element_line(color = "gray90", linewidth = 0.5),
      panel.grid.minor = element_blank(),
      strip.text = element_text(face = "bold", size = 12),
      plot.margin = margin(10, 10, 10, 10)
    )
}

create_auc_bar_plot <- function(data, task_name_filter, auc_type, y_label, show_x_text = FALSE) {
  plot_data <- data %>%
    filter(task_name == task_name_filter) %>%
    group_by(condition) %>%
    summarise(
      mean_value = mean(.data[[auc_type]], na.rm = TRUE),
      se_value = sd(.data[[auc_type]], na.rm = TRUE) / sqrt(n()),
      .groups = 'drop'
    )
  
  p <- plot_data %>%
    ggplot(aes(x = condition, y = mean_value, fill = condition)) +
    geom_bar(stat = "identity", position = position_dodge(width = 0.8), width = 0.7) +
    geom_errorbar(aes(ymin = mean_value - se_value, ymax = mean_value + se_value),
                  position = position_dodge(width = 0.8), width = 0.2, linewidth = 0.8) +
    scale_fill_manual(values = condition_colors, labels = c("Easy/Low", "Easy/High", "Hard/Low", "Hard/High")) +
    labs(title = task_name_filter, x = NULL, y = NULL, fill = "Condition") +
    theme_publication() +
    theme(
      plot.title = element_text(hjust = 0.5, size = 12, face = "bold"),
      legend.position = "none"
    )

  if (show_x_text) {
    p <- p + theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 10))
  } else {
    p <- p + theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())
  }

  # Add y-axis label and dynamic limits for Total AUC
  if (auc_type == "mean_total_auc") {
    # The ylim is now applied to all total AUC plots outside this function
  }

  if (task_name_filter == "CDT") {
    p <- p + labs(y = y_label)
  }
  
  return(p)
}

# Calculate unified y-axis limits for all Total AUC plots
total_auc_plot_data <- combined_auc_data %>%
  group_by(task_name, condition) %>%
  summarise(
    mean_value = mean(mean_total_auc, na.rm = TRUE),
    se_value = sd(mean_total_auc, na.rm = TRUE) / sqrt(n()),
    .groups = 'drop'
  )

min_total_auc <- min(total_auc_plot_data$mean_value - total_auc_plot_data$se_value, na.rm = TRUE)
max_total_auc <- max(total_auc_plot_data$mean_value + total_auc_plot_data$se_value, na.rm = TRUE)
y_lim_buffer_total <- (max_total_auc - min_total_auc) * 0.1
unified_total_auc_ylim <- c(min_total_auc - y_lim_buffer_total, max_total_auc + y_lim_buffer_total)


p_total_cdt <- create_auc_bar_plot(combined_auc_data, "CDT", "mean_total_auc", "Total AUC", show_x_text = FALSE) +
  coord_cartesian(ylim = unified_total_auc_ylim)
p_total_adt <- create_auc_bar_plot(combined_auc_data, "ADT", "mean_total_auc", "", show_x_text = FALSE) +
  coord_cartesian(ylim = unified_total_auc_ylim)
p_total_vdt <- create_auc_bar_plot(combined_auc_data, "VDT", "mean_total_auc", "", show_x_text = FALSE) +
  coord_cartesian(ylim = unified_total_auc_ylim)

# 1. Create separate Total AUC plot (all three tasks)
total_auc_plots <- (p_total_cdt + p_total_adt + p_total_vdt) +
  plot_layout(guides = "collect") &
  theme(legend.position = "bottom",
        legend.direction = "horizontal",
        legend.title = element_text(face = "bold", size = 12),
        legend.text = element_text(size = 11))

# 2. Create separate Cognitive AUC plot (ADT and VDT only, per Lani's recommendations)
p_cognitive_adt <- create_auc_bar_plot(combined_auc_data, "ADT", "mean_cognitive_auc", "Cognitive AUC", show_x_text = TRUE)
p_cognitive_vdt <- create_auc_bar_plot(combined_auc_data, "VDT", "mean_cognitive_auc", "", show_x_text = TRUE)

cognitive_auc_plots <- (p_cognitive_adt + p_cognitive_vdt) +
  plot_layout(guides = "collect") &
  theme(legend.position = "bottom",
        legend.direction = "horizontal",
        legend.title = element_text(face = "bold", size = 12),
        legend.text = element_text(size = 11))

# Save separate plots
total_auc_file <- "Figure_Total_AUC_Publication_Ready.png"
cognitive_auc_file <- "Figure_Cognitive_AUC_Publication_Ready.png"

ggsave(file.path(PLOTS_DIR, total_auc_file), total_auc_plots, width = 12, height = 4, dpi = 300)
ggsave(file.path(PLOTS_DIR, cognitive_auc_file), cognitive_auc_plots, width = 8, height = 4, dpi = 300)

cat(paste("✓ Total AUC plot saved:", file.path(PLOTS_DIR, total_auc_file), "\n"))
cat(paste("✓ Cognitive AUC plot saved:", file.path(PLOTS_DIR, cognitive_auc_file), "\n"))
