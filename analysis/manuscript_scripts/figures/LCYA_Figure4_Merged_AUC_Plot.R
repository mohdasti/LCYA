#!/usr/bin/env Rscript

# Script to generate Figure 4: Merged Total AUC and Cognitive AUC Plot
# Top row: Total AUC (CDT, ADT, VDT)
# Bottom row: Cognitive AUC (CDT [excluded], ADT, VDT)
# Based on LCYA_Updated_Combined_AUC_Plots.R

suppressPackageStartupMessages({
  library(tidyverse)
  library(patchwork)
})

# Set up directories
BASE_DIR <- "/Users/mohdasti/Documents/LC–YA"
DATA_DIR <- file.path(BASE_DIR, "100 Hz")
OUTPUT_DIR <- file.path(BASE_DIR, "GitHub_Ready_Analyses/05_Manuscript_Figures/Manuscript_Figures_Only")

# Create output directory if it doesn't exist
if (!dir.exists(OUTPUT_DIR)) {
  dir.create(OUTPUT_DIR, recursive = TRUE)
}

# --- Data Loading and Preprocessing Functions ---

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
cat("Loading and processing data...\n")
all_cognitive_auc_data <- list()
all_total_auc_data <- list()

for (task_name in names(task_configs)) {
  cat("Processing", task_name, "...\n")
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

cat("Data processing complete!\n")

# --- Plotting Setup ---

# Color scheme: Easy (blue), Hard (pink) × Low (light), High (dark)
condition_colors <- c(
  "Easy / Low" = "#5DADE2",   # Light blue
  "Easy / High" = "#2E86AB",  # Dark blue
  "Hard / Low" = "#EC70AB",   # Light pink
  "Hard / High" = "#A23B72"   # Dark pink
)

theme_publication <- function() {
  theme_minimal(base_size = 12) +
    theme(
      text = element_text(family = "Helvetica", color = "black"),
      plot.title = element_text(face = "bold", hjust = 0.5, size = 13),
      axis.title = element_text(face = "bold", size = 11),
      axis.text = element_text(size = 10, color = "black"),
      axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
      legend.title = element_text(face = "bold", size = 11),
      legend.text = element_text(size = 10),
      panel.grid.major = element_line(color = "gray90", linewidth = 0.5),
      panel.grid.minor = element_blank(),
      strip.text = element_text(face = "bold", size = 12),
      plot.margin = margin(5, 5, 5, 5)
    )
}

create_auc_bar_plot <- function(data, task_name_filter, auc_type, y_label, show_y_label = FALSE, show_x_text = TRUE, show_y_ticks = TRUE) {
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
    scale_fill_manual(values = condition_colors, 
                      name = "Difficulty / Effort",
                      labels = c("Easy/Low", "Easy/High", "Hard/Low", "Hard/High")) +
    labs(title = task_name_filter, x = NULL, y = NULL) +
    theme_publication()

  if (!show_x_text) {
    p <- p + theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())
  }
  
  if (!show_y_ticks) {
    p <- p + theme(axis.text.y = element_blank(), axis.ticks.y = element_blank())
  }
  
  if (show_y_label) {
    p <- p + labs(y = y_label)
  }
  
  return(p)
}

# --- Create Merged 2x3 Plot ---
cat("Creating merged figure...\n")

# Calculate unified y-axis limits for Total AUC plots
total_auc_plot_data <- combined_auc_data %>%
  group_by(task_name, condition) %>%
  summarise(
    mean_value = mean(mean_total_auc, na.rm = TRUE),
    se_value = sd(mean_total_auc, na.rm = TRUE) / sqrt(n()),
    .groups = 'drop'
  )

min_total <- min(total_auc_plot_data$mean_value - total_auc_plot_data$se_value, na.rm = TRUE)
max_total <- max(total_auc_plot_data$mean_value + total_auc_plot_data$se_value, na.rm = TRUE)
buffer_total <- (max_total - min_total) * 0.1
ylim_total <- c(min_total - buffer_total, max_total + buffer_total)

# Calculate unified y-axis limits for Cognitive AUC plots (ADT and VDT only)
cognitive_auc_plot_data <- combined_auc_data %>%
  filter(task_name %in% c("ADT", "VDT")) %>%
  group_by(task_name, condition) %>%
  summarise(
    mean_value = mean(mean_cognitive_auc, na.rm = TRUE),
    se_value = sd(mean_cognitive_auc, na.rm = TRUE) / sqrt(n()),
    .groups = 'drop'
  )

min_cog <- min(cognitive_auc_plot_data$mean_value - cognitive_auc_plot_data$se_value, na.rm = TRUE)
max_cog <- max(cognitive_auc_plot_data$mean_value + cognitive_auc_plot_data$se_value, na.rm = TRUE)
buffer_cog <- (max_cog - min_cog) * 0.1
ylim_cog <- c(min_cog - buffer_cog, max_cog + buffer_cog)

# Top row: Total AUC (all three tasks)
# Only show y-axis ticks on leftmost (CDT) plot
p_total_cdt <- create_auc_bar_plot(combined_auc_data, "CDT", "mean_total_auc", 
                                   "Total AUC", show_y_label = TRUE, show_x_text = FALSE, show_y_ticks = TRUE) +
  coord_cartesian(ylim = ylim_total)

p_total_adt <- create_auc_bar_plot(combined_auc_data, "ADT", "mean_total_auc", 
                                   "", show_y_label = FALSE, show_x_text = FALSE, show_y_ticks = FALSE) +
  coord_cartesian(ylim = ylim_total)

p_total_vdt <- create_auc_bar_plot(combined_auc_data, "VDT", "mean_total_auc", 
                                   "", show_y_label = FALSE, show_x_text = FALSE, show_y_ticks = FALSE) +
  coord_cartesian(ylim = ylim_total)

# Bottom row: Cognitive AUC (ADT and VDT only)
# Only show y-axis ticks on leftmost (ADT) plot
p_cognitive_adt <- create_auc_bar_plot(combined_auc_data, "ADT", "mean_cognitive_auc", 
                                       "Cognitive AUC", show_y_label = TRUE, show_x_text = TRUE, show_y_ticks = TRUE) +
  coord_cartesian(ylim = ylim_cog)

p_cognitive_vdt <- create_auc_bar_plot(combined_auc_data, "VDT", "mean_cognitive_auc", 
                                       "", show_y_label = FALSE, show_x_text = TRUE, show_y_ticks = FALSE) +
  coord_cartesian(ylim = ylim_cog)

# Combine plots in 2x3 grid with shared legend
# No title or caption - these will be in the manuscript
merged_plot <- (p_total_cdt | p_total_adt | p_total_vdt) /
               (p_cognitive_adt | p_cognitive_vdt | plot_spacer()) +
  plot_layout(heights = c(1, 1), guides = "collect") &
  theme(legend.position = "bottom", legend.direction = "horizontal")

final_plot <- merged_plot

# Save the merged plot
output_file <- file.path(OUTPUT_DIR, "Figure4_Merged_Total_Cognitive_AUC.png")
ggsave(output_file, final_plot, width = 14, height = 10, dpi = 300, bg = "white")

cat("✓ Merged Figure 4 saved to:", output_file, "\n")

# Also save individual plots for reference
total_auc_only <- (p_total_cdt | p_total_adt | p_total_vdt) +
  plot_layout(guides = "collect") &
  theme(legend.position = "bottom", legend.direction = "horizontal")

cognitive_auc_only <- (p_cognitive_adt | p_cognitive_vdt) +
  plot_layout(guides = "collect") &
  theme(legend.position = "bottom", legend.direction = "horizontal")

ggsave(file.path(OUTPUT_DIR, "Figure4_Total_AUC.png"), total_auc_only, 
       width = 14, height = 5, dpi = 300, bg = "white")
ggsave(file.path(OUTPUT_DIR, "Figure4_Cognitive_AUC.png"), cognitive_auc_only, 
       width = 10, height = 5, dpi = 300, bg = "white")

cat("✓ Individual plots also saved:\n")
cat("  - Figure4_Total_AUC.png\n")
cat("  - Figure4_Cognitive_AUC.png\n")
cat("\nComplete!\n")

