#!/usr/bin/env Rscript

# Figure2 Clean Final Version
# 1. Remove significance brackets
# 2. Remove x-axis label from accuracy plots (keep only on reaction time plots)
# 3. Change "Log-Reaction Time" to "Reaction Time"

suppressPackageStartupMessages({
  library(tidyverse)
  library(patchwork)
})

# Set up directories
BASE_DIR <- "/Users/mohdasti/Documents/LC–YA"
FOUR_LEVEL_DIR <- file.path(BASE_DIR, "Complete_Manuscript_Plots", "Four_Level_Difficulty_Plots")

# Load the four-level data
four_level_data <- read_csv(file.path(BASE_DIR, "Complete_Manuscript_Plots", "Four_Level_Difficulty_Plots", "corrected_four_level_complete_data.csv"), show_col_types = FALSE)

# Prepare behavioral data for Easy/Hard conditions
behavioral_simple <- four_level_data %>%
    mutate(
        # Create binary difficulty: Easy vs Hard
        difficulty_binary = case_when(
            difficulty_4level %in% c("Level1", "Level2") ~ "Easy",
            difficulty_4level %in% c("Level3", "Level4") ~ "Hard",
            TRUE ~ NA_character_
        ),
        # Create condition labels that match our color scheme
        condition = paste(difficulty_binary, effort, sep = " / ")
    ) %>%
    filter(!is.na(difficulty_binary)) %>%
    group_by(task, difficulty_binary, effort, condition) %>%
    summarise(
        accuracy_mean = mean(accuracy, na.rm = TRUE),
        accuracy_se = sd(accuracy, na.rm = TRUE) / sqrt(n()),
        rt_mean = mean(rt_scaled, na.rm = TRUE),
        rt_se = sd(rt_scaled, na.rm = TRUE) / sqrt(n()),
        # Fix log-RT: use raw RT first, then log transform
        logrt_mean = mean(log(rt_ms), na.rm = TRUE),
        logrt_se = sd(log(rt_ms), na.rm = TRUE) / sqrt(n()),
        n_trials = n(),
        .groups = 'drop'
    ) %>%
    mutate(
        task = factor(task, levels = c("CDT", "ADT", "VDT")),
        difficulty_binary = factor(difficulty_binary, levels = c("Easy", "Hard")),
        effort = factor(effort, levels = c("Low", "High")),
        condition = factor(condition, levels = c("Easy / Low", "Easy / High", "Hard / Low", "Hard / High"))
    )

# Color scheme matching your requirements
condition_colors <- c(
    "Easy / Low" = "#5DADE2",   # Light blue
    "Easy / High" = "#2E86AB",  # Dark blue
    "Hard / Low" = "#EC70AB",   # Light pink
    "Hard / High" = "#A23B72"   # Dark pink
)

# Publication theme (remove borders)
theme_publication <- function() {
    theme_minimal() +
    theme(
        text = element_text(size = 12),
        plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
        axis.title = element_text(size = 12, face = "bold"),
        axis.text = element_text(size = 10),
        legend.position = "bottom",
        legend.title = element_text(size = 11, face = "bold"),
        legend.text = element_text(size = 10),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(color = "grey90", linewidth = 0.3),
        # Remove panel borders
        panel.border = element_blank(),
        # Remove strip borders
        strip.background = element_blank(),
        strip.text = element_text(size = 11, face = "bold")
    )
}

# Accuracy plot - Three columns (CDT, ADT, VDT) - NO x-axis label
p_accuracy_simple <- ggplot(behavioral_simple, aes(x = difficulty_binary, y = accuracy_mean,
                                                  fill = condition)) +
    geom_bar(stat = "identity", position = position_dodge(width = 0.8), width = 0.7) +
    geom_errorbar(aes(ymin = accuracy_mean - accuracy_se,
                      ymax = accuracy_mean + accuracy_se),
                  position = position_dodge(width = 0.8), width = 0.2, linewidth = 0.8) +
    facet_wrap(~task, ncol = 3) +
    scale_fill_manual(values = condition_colors) +
    labs(
        title = "Accuracy",
        x = NULL,  # Remove x-axis label
        y = "Proportion Correct",
        fill = "Condition"
    ) +
    theme_publication() +
    theme(axis.text.x = element_text(angle = 0, hjust = 0.5),
          legend.position = "none")

# Reaction Time plot - Three columns (CDT, ADT, VDT) - WITH x-axis label
p_logrt_simple <- ggplot(behavioral_simple, aes(x = difficulty_binary, y = logrt_mean,
                                                fill = condition)) +
    geom_bar(stat = "identity", position = position_dodge(width = 0.8), width = 0.7) +
    geom_errorbar(aes(ymin = logrt_mean - logrt_se,
                      ymax = logrt_mean + logrt_se),
                  position = position_dodge(width = 0.8), width = 0.2, linewidth = 0.8) +
    facet_wrap(~task, ncol = 3) +
    scale_fill_manual(values = condition_colors) +
    labs(
        title = "Reaction Time",  # Changed from "Log-Reaction Time"
        x = "Task Difficulty",    # Keep x-axis label here
        y = "Log-Reaction Time",
        fill = "Condition"
    ) +
    theme_publication() +
    theme(axis.text.x = element_text(angle = 0, hjust = 0.5),
          legend.position = "bottom",
          legend.direction = "horizontal")

# Combine plots (two rows: accuracy top, reaction time bottom)
fig2_simple <- p_accuracy_simple / p_logrt_simple +
    plot_layout(guides = "collect") &
    theme(legend.position = "bottom")

# Save the clean final figure
ggsave(file.path(FOUR_LEVEL_DIR, "Figure2_Task_Performance_Effects_Clean_Final.png"),
       fig2_simple, width = 12, height = 8, dpi = 300)
ggsave(file.path(FOUR_LEVEL_DIR, "Figure2_Task_Performance_Effects_Clean_Final.pdf"),
       fig2_simple, width = 12, height = 8)

cat("✓ Clean Final Figure 2 saved: Task Performance Effects\n")
cat("✓ Removed significance brackets\n")
cat("✓ Removed x-axis label from accuracy plots\n")
cat("✓ Changed title to 'Reaction Time'\n")
cat("✓ Kept x-axis label only on reaction time plots\n")
cat("✓ Removed panel borders\n")

