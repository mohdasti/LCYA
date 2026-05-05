#!/usr/bin/env Rscript
# =============================================================================
# LCYA Revision — 05: Updated Figures with Individual Data Points
#
# Purpose:
#   Produce revised versions of Figures 2 and 4 with individual participant
#   data points (jittered dots) overlaid on group mean bars, with connecting
#   lines linking the same participant across conditions. This provides full
#   transparency about the distribution of N=38 participants.
#
#   Also generates a Supplementary Figure for Cognitive AUC results, which
#   are moved from the main text to Supplementary Material per Reviewer 1,
#   Minor #2.
#
# Outputs (./outputs/):
#   Figure2_Revised_Behavioral_IndivPoints.pdf/.png  — Accuracy + RT (3 tasks)
#   Figure4_Revised_TotalAUC_IndivPoints.pdf/.png    — Total AUC (3 tasks)
#   FigureS1_CognitiveAUC_Supplementary.pdf/.png     — Cognitive AUC (ADT + VDT)
#
# Reviewer context:
#   R1 Minor #4  — individual participant data points on Figures 2 and 4
#   R1 Minor #2  — Cognitive AUC relocated to Supplementary Material
#
# Date: March 2026
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(patchwork)
})

# =============================================================================
# CONFIGURATION
# =============================================================================

BASE_DIR   <- "/Users/mohdasti/Documents/LC\u2013YA"
DATA_DIR   <- file.path(BASE_DIR, "100 Hz")
OUTPUT_DIR <- file.path(BASE_DIR, "GitHub_Ready_Analyses",
                        "06_Revision_Analyses", "05_Updated_Figures", "outputs")

if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)

TASKS <- c("CDT", "ADT", "VDT")

# Align with manuscript Figure 2 (Four_Level: Level1+2→Easy, Level3+4→Hard) /
# corrected_four_level_complete_data.csv: Easy / Hard stimulus levels per task.
DIFF_CODING <- list(
  CDT = list(easy = c(45, 90),        hard = c(5, 20)),
  ADT = list(easy = c(32, 128),      hard = c(4, 8)),
  VDT = list(easy = c(0.16, 0.32),   hard = c(0.04, 0.08))
)

TASK_CFG <- list(
  CDT = list(b2b_dur = 0.5, cog_latency = 0.3, total_start = 0,
             s2_median = 4.39, resp_median = 6.08,
             s2_label = "Arrow", resp_label = "Response", conf_label = "Confidence"),
  ADT = list(b2b_dur = 0.5, cog_latency = 0.3, total_start = 0,
             s2_median = 3.78, resp_median = 5.49,
             s2_label = "Stimulus", resp_label = "Response", conf_label = "Confidence"),
  VDT = list(b2b_dur = 0.5, cog_latency = 0.3, total_start = 0,
             s2_median = 3.78, resp_median = 5.49,
             s2_label = "Stimulus", resp_label = "Response", conf_label = "Confidence")
)

# Color scheme — consistent with existing manuscript figures
CONDITION_COLORS <- c(
  "Easy / Low"  = "#5DADE2",
  "Easy / High" = "#2E86AB",
  "Hard / Low"  = "#EC70AB",
  "Hard / High" = "#A23B72"
)

cat("=== LCYA Revision: Updated Figures with Individual Data Points ===\n")
cat("Output directory:", OUTPUT_DIR, "\n\n")

# =============================================================================
# SHARED HELPERS
# =============================================================================

load_raw <- function(task_name) {
  files <- list.files(DATA_DIR,
                      pattern = paste0(".*", task_name, "_DS100_merged\\.csv$"),
                      full.names = TRUE)
  stopifnot(length(files) > 0)
  map_dfr(files, ~ read_csv(.x, show_col_types = FALSE) %>%
            mutate(task = task_name)) %>%
    filter(stimLev != 0) %>%
    mutate(
      difficulty = case_when(
        stimLev %in% DIFF_CODING[[task_name]]$easy ~ "Easy",
        stimLev %in% DIFF_CODING[[task_name]]$hard ~ "Hard",
        TRUE ~ NA_character_
      ),
      effort = case_when(
        isStrength == 0 ~ "Low",
        isStrength == 1 ~ "High",
        TRUE ~ NA_character_
      )
    ) %>%
    filter(!is.na(difficulty), !is.na(effort))
}

calc_auc_trap <- function(t, y, t0, t1) {
  ok <- !is.na(y) & (t >= t0) & (t <= t1)
  if (sum(ok) < 2) return(NA_real_)
  ts <- t[ok]; ys <- y[ok]; ord <- order(ts)
  sum(0.5 * (ys[ord][-length(ys[ord])] + ys[ord][-1]) * diff(ts[ord]))
}

compute_trial_auc <- function(raw, cfg) {
  squeeze_t <- raw %>%
    filter(duration_label == "Squeeze") %>%
    group_by(sub, trial_index) %>%
    summarise(squeeze_time = first(time), .groups = "drop")

  evt <- raw %>%
    filter(duration_label %in% c("Squeeze", cfg$s2_label,
                                 cfg$resp_label, cfg$conf_label)) %>%
    group_by(sub, trial_index, duration_label) %>%
    summarise(evt_time = first(time), .groups = "drop") %>%
    pivot_wider(names_from = duration_label, values_from = evt_time, names_prefix = "t_")

  events <- squeeze_t %>%
    left_join(evt, by = c("sub", "trial_index")) %>%
    mutate(
      s2_rel   = .data[[paste0("t_", cfg$s2_label)]] - squeeze_time,
      resp_rel = t_Response - squeeze_time
    ) %>%
    mutate(
      s2_rel   = ifelse(is.na(s2_rel),   cfg$s2_median,   s2_rel),
      resp_rel = ifelse(is.na(resp_rel), cfg$resp_median, resp_rel)
    ) %>%
    select(sub, trial_index, squeeze_time, s2_rel, resp_rel)

  raw %>%
    left_join(squeeze_t, by = c("sub", "trial_index")) %>%
    left_join(events,    by = c("sub", "trial_index", "squeeze_time")) %>%
    filter(!is.na(squeeze_time)) %>%
    mutate(t_sq = time - squeeze_time) %>%
    group_by(sub, trial_index, task, difficulty, effort) %>%
    summarise(
      b0  = mean(pupil[t_sq >= -0.5 & t_sq < 0], na.rm = TRUE),
      b2b = mean(pupil[t_sq >= (first(s2_rel) - cfg$b2b_dur) &
                         t_sq <  first(s2_rel)],  na.rm = TRUE),
      Total_AUC    = calc_auc_trap(t_sq, pupil,        cfg$total_start, first(resp_rel)),
      Cognitive_AUC = calc_auc_trap(t_sq, pupil - b2b,
                                    first(s2_rel) + cfg$cog_latency, first(resp_rel)),
      .groups = "drop"
    ) %>%
    mutate(
      difficulty = factor(difficulty, levels = c("Easy", "Hard")),
      effort     = factor(effort,     levels = c("Low",  "High")),
      condition  = paste(as.character(difficulty), as.character(effort), sep = " / ")
    )
}

# =============================================================================
# LOAD ALL DATA
# =============================================================================

cat("Loading and computing data for all tasks...\n")

# Behavioral data: load from the same corrected CSV used by the original Figure 2
# (corrected_four_level_complete_data.csv already has the right Easy/Hard labels
#  and cleaned accuracy/RT values that match the published figure).
CORRECTED_BEH_PATH <- file.path(BASE_DIR, "Complete_Manuscript_Plots",
                                 "Four_Level_Difficulty_Plots",
                                 "corrected_four_level_complete_data.csv")

beh_combined <- read_csv(CORRECTED_BEH_PATH, show_col_types = FALSE) %>%
  filter(!is.na(rt_ms), rt_ms > 0) %>%
  mutate(
    task       = factor(task, levels = TASKS),
    difficulty = factor(difficulty, levels = c("Easy", "Hard")),
    effort     = factor(effort,     levels = c("Low",  "High")),
    condition  = factor(
      paste(as.character(difficulty), as.character(effort), sep = " / "),
      levels = names(CONDITION_COLORS)
    )
  )

# AUC data: still computed from raw 100 Hz pupil files
auc_all <- list()
for (task_name in TASKS) {
  cat("  Processing", task_name, "...\n")
  raw <- load_raw(task_name)
  auc_all[[task_name]] <- compute_trial_auc(raw, TASK_CFG[[task_name]])
}

auc_combined <- bind_rows(auc_all) %>%
  mutate(task = factor(task, levels = TASKS),
         condition = factor(condition, levels = names(CONDITION_COLORS)))

cat("Data loaded.\n\n")

# =============================================================================
# SHARED PLOT THEME
# =============================================================================

theme_pub <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      panel.grid.minor  = element_blank(),
      panel.grid.major  = element_line(colour = "grey92", linewidth = 0.3),
      panel.border      = element_blank(),
      strip.background  = element_blank(),
      strip.text        = element_text(face = "bold", size = 12),
      axis.title        = element_text(face = "bold"),
      axis.text         = element_text(size = 9),
      legend.position   = "bottom",
      legend.title      = element_text(face = "bold", size = 10),
      legend.text       = element_text(size = 9)
    )
}

# Helper to add individual points + connecting lines to any bar plot
add_individual_layer <- function(sub_data, point_alpha = 0.35, line_alpha = 0.2,
                                 point_size = 1.6, line_width = 0.35) {
  list(
    geom_point(data = sub_data,
               aes(y = value, colour = condition),
               position = position_dodge(0.7),
               size = point_size, alpha = point_alpha, shape = 16,
               show.legend = FALSE),
    geom_line(data = sub_data,
              aes(y = value, group = interaction(sub, effort), colour = condition),
              position = position_dodge(0.7),
              linewidth = line_width, alpha = line_alpha,
              show.legend = FALSE),
    scale_colour_manual(values = CONDITION_COLORS)
  )
}

# =============================================================================
# FIGURE 2 REVISED: BEHAVIORAL (ACCURACY + RT)
# =============================================================================

cat("Building Figure 2 (Accuracy + RT with individual points)...\n")

# Subject-level means for behavioral (accuracy from corrected CSV)
sub_beh <- beh_combined %>%
  group_by(sub, task, difficulty, effort, condition) %>%
  summarise(
    acc_mean = mean(accuracy, na.rm = TRUE),
    rt_mean  = mean(rt_ms,   na.rm = TRUE),
    .groups  = "drop"
  ) %>%
  mutate(condition = factor(condition, levels = names(CONDITION_COLORS)))

# Group means + SE
grp_beh <- beh_combined %>%
  group_by(task, difficulty, effort, condition) %>%
  summarise(
    acc_mean = mean(accuracy, na.rm = TRUE),
    acc_se   = sd(accuracy,   na.rm = TRUE) / sqrt(n_distinct(sub)),
    rt_mean  = mean(rt_ms,    na.rm = TRUE),
    rt_se    = sd(rt_ms,      na.rm = TRUE) / sqrt(n_distinct(sub)),
    .groups  = "drop"
  ) %>%
  mutate(condition = factor(condition, levels = names(CONDITION_COLORS)))

# ACCURACY ROW
p_acc <- ggplot(grp_beh,
                aes(x = difficulty, y = acc_mean,
                    fill = condition, group = condition)) +
  geom_col(position = position_dodge(0.7), width = 0.62, alpha = 0.88) +
  geom_errorbar(aes(ymin = acc_mean - acc_se, ymax = acc_mean + acc_se),
                position = position_dodge(0.7), width = 0.2, linewidth = 0.6) +
  geom_point(data = sub_beh %>% rename(value = acc_mean),
             aes(y = value, colour = condition),
             position = position_dodge(0.7),
             size = 1.5, alpha = 0.35, shape = 16, show.legend = FALSE) +
  geom_line(data = sub_beh %>% rename(value = acc_mean),
            aes(y = value, group = interaction(sub, effort), colour = condition),
            position = position_dodge(0.7),
            linewidth = 0.3, alpha = 0.2, show.legend = FALSE) +
  facet_wrap(~ task, nrow = 1) +
  scale_fill_manual(values = CONDITION_COLORS,
                    name   = "Condition (Difficulty / Effort)") +
  scale_colour_manual(values = CONDITION_COLORS) +
  scale_y_continuous(limits = c(0, 1.05), labels = scales::percent_format()) +
  labs(x = NULL, y = "Accuracy (proportion correct)") +
  theme_pub()

# RT ROW
p_rt <- ggplot(grp_beh,
               aes(x = difficulty, y = rt_mean,
                   fill = condition, group = condition)) +
  geom_col(position = position_dodge(0.7), width = 0.62, alpha = 0.88) +
  geom_errorbar(aes(ymin = rt_mean - rt_se, ymax = rt_mean + rt_se),
                position = position_dodge(0.7), width = 0.2, linewidth = 0.6) +
  geom_point(data = sub_beh %>% rename(value = rt_mean),
             aes(y = value, colour = condition),
             position = position_dodge(0.7),
             size = 1.5, alpha = 0.35, shape = 16, show.legend = FALSE) +
  geom_line(data = sub_beh %>% rename(value = rt_mean),
            aes(y = value, group = interaction(sub, effort), colour = condition),
            position = position_dodge(0.7),
            linewidth = 0.3, alpha = 0.2, show.legend = FALSE) +
  facet_wrap(~ task, nrow = 1) +
  scale_fill_manual(values = CONDITION_COLORS,
                    name   = "Condition (Difficulty / Effort)") +
  scale_colour_manual(values = CONDITION_COLORS) +
  labs(x = "Task Difficulty", y = "Reaction Time (ms)") +
  theme_pub()

fig2 <- p_acc / p_rt +
  plot_layout(guides = "collect") &
  theme(legend.position = "bottom")

ggsave(file.path(OUTPUT_DIR, "Figure2_Revised_Behavioral_IndivPoints.pdf"),
       fig2, width = 10, height = 7, useDingbats = FALSE)
ggsave(file.path(OUTPUT_DIR, "Figure2_Revised_Behavioral_IndivPoints.png"),
       fig2, width = 10, height = 7, dpi = 300)
cat("Saved: Figure2_Revised_Behavioral_IndivPoints.pdf/.png\n")

# =============================================================================
# FIGURE 4 REVISED: TOTAL AUC WITH INDIVIDUAL POINTS
# =============================================================================

cat("Building Figure 4 (Total AUC with individual points)...\n")

# Subject-level Total AUC means
sub_total <- auc_combined %>%
  filter(!is.na(Total_AUC)) %>%
  group_by(sub, task, difficulty, effort, condition) %>%
  summarise(value = mean(Total_AUC, na.rm = TRUE), .groups = "drop") %>%
  mutate(condition = factor(condition, levels = names(CONDITION_COLORS)))

# Group-level Total AUC means
grp_total <- auc_combined %>%
  filter(!is.na(Total_AUC)) %>%
  group_by(task, difficulty, effort, condition) %>%
  summarise(
    auc_mean = mean(Total_AUC, na.rm = TRUE),
    auc_se   = sd(Total_AUC,   na.rm = TRUE) / sqrt(n_distinct(sub)),
    .groups  = "drop"
  ) %>%
  mutate(condition = factor(condition, levels = names(CONDITION_COLORS)))

# Compute y-axis limits from data range (individual points + SE) with 5% buffer
total_all_vals <- c(sub_total$value,
                    grp_total$auc_mean - grp_total$auc_se,
                    grp_total$auc_mean + grp_total$auc_se)
total_ylim <- range(total_all_vals, na.rm = TRUE)
total_buf  <- diff(total_ylim) * 0.05
total_ylim <- total_ylim + c(-total_buf, total_buf)

p_total <- ggplot(grp_total,
                  aes(x = difficulty, y = auc_mean,
                      fill = condition, group = condition)) +
  geom_col(position = position_dodge(0.7), width = 0.62, alpha = 0.88) +
  geom_errorbar(aes(ymin = auc_mean - auc_se, ymax = auc_mean + auc_se),
                position = position_dodge(0.7), width = 0.2, linewidth = 0.6) +
  geom_point(data = sub_total,
             aes(y = value, colour = condition),
             position = position_dodge(0.7),
             size = 1.5, alpha = 0.35, shape = 16, show.legend = FALSE) +
  geom_line(data = sub_total,
            aes(y = value, group = interaction(sub, effort), colour = condition),
            position = position_dodge(0.7),
            linewidth = 0.3, alpha = 0.2, show.legend = FALSE) +
  facet_wrap(~ task, nrow = 1) +
  scale_fill_manual(values  = CONDITION_COLORS,
                    name    = "Condition (Difficulty / Effort)") +
  scale_colour_manual(values = CONDITION_COLORS) +
  coord_cartesian(ylim = total_ylim) +
  labs(
    x = "Task Difficulty",
    y = "Total AUC (arbitrary units)"
  ) +
  theme_pub()

ggsave(file.path(OUTPUT_DIR, "Figure4_Revised_TotalAUC_IndivPoints.pdf"),
       p_total, width = 10, height = 4.5, useDingbats = FALSE)
ggsave(file.path(OUTPUT_DIR, "Figure4_Revised_TotalAUC_IndivPoints.png"),
       p_total, width = 10, height = 4.5, dpi = 300)
cat("Saved: Figure4_Revised_TotalAUC_IndivPoints.pdf/.png\n")

# =============================================================================
# SUPPLEMENTARY FIGURE S1: COGNITIVE AUC (ADT + VDT only)
#
# Cognitive AUC is moved to Supplementary Material per Reviewer 1, Minor #2.
# Includes individual data points to maintain consistency with main figures.
# Caption should note the exploratory nature and 300ms window limitation.
# =============================================================================

cat("Building Supplementary Figure S1 (Cognitive AUC)...\n")

cog_tasks <- c("ADT", "VDT")

sub_cog <- auc_combined %>%
  filter(task %in% cog_tasks, !is.na(Cognitive_AUC)) %>%
  group_by(sub, task, difficulty, effort, condition) %>%
  summarise(value = mean(Cognitive_AUC, na.rm = TRUE), .groups = "drop") %>%
  mutate(condition = factor(condition, levels = names(CONDITION_COLORS)))

grp_cog <- auc_combined %>%
  filter(task %in% cog_tasks, !is.na(Cognitive_AUC)) %>%
  group_by(task, difficulty, effort, condition) %>%
  summarise(
    auc_mean = mean(Cognitive_AUC, na.rm = TRUE),
    auc_se   = sd(Cognitive_AUC,   na.rm = TRUE) / sqrt(n_distinct(sub)),
    .groups  = "drop"
  ) %>%
  mutate(condition = factor(condition, levels = names(CONDITION_COLORS)))

p_cog <- ggplot(grp_cog,
                aes(x = difficulty, y = auc_mean,
                    fill = condition, group = condition)) +
  geom_col(position = position_dodge(0.7), width = 0.62, alpha = 0.88) +
  geom_errorbar(aes(ymin = auc_mean - auc_se, ymax = auc_mean + auc_se),
                position = position_dodge(0.7), width = 0.2, linewidth = 0.6) +
  geom_point(data = sub_cog,
             aes(y = value, colour = condition),
             position = position_dodge(0.7),
             size = 1.5, alpha = 0.35, shape = 16, show.legend = FALSE) +
  geom_line(data = sub_cog,
            aes(y = value, group = interaction(sub, effort), colour = condition),
            position = position_dodge(0.7),
            linewidth = 0.3, alpha = 0.2, show.legend = FALSE) +
  facet_wrap(~ task, nrow = 1) +
  scale_fill_manual(values  = CONDITION_COLORS,
                    name    = "Condition (Difficulty / Effort)") +
  scale_colour_manual(values = CONDITION_COLORS) +
  labs(
    title    = "Supplementary Figure S1: Cognitive AUC (Exploratory)",
    subtitle = paste0("Cognitive AUC: baseline-corrected from 300 ms post-probe onset to response window onset.\n",
                      "CDT excluded (probe presented during response window). Treat as exploratory — see limitations."),
    x        = "Task Difficulty",
    y        = "Cognitive AUC (arbitrary units)"
  ) +
  theme_pub() +
  theme(plot.subtitle = element_text(size = 8.5, colour = "grey40"))

ggsave(file.path(OUTPUT_DIR, "FigureS1_CognitiveAUC_Supplementary.pdf"),
       p_cog, width = 7, height = 4.5, useDingbats = FALSE)
ggsave(file.path(OUTPUT_DIR, "FigureS1_CognitiveAUC_Supplementary.png"),
       p_cog, width = 7, height = 4.5, dpi = 300)
cat("Saved: FigureS1_CognitiveAUC_Supplementary.pdf/.png\n")

cat("\n=== DONE ===\n")
cat("All revised figures saved to:", OUTPUT_DIR, "\n")
cat("\nFigure notes:\n")
cat("  Figure 2:  Accuracy (top) and RT (bottom) — 2-row layout, 3 tasks.\n")
cat("  Figure 4:  Total AUC — single row, 3 tasks.\n")
cat("  Figure S1: Cognitive AUC (ADT + VDT only) — Supplementary Material.\n")
cat("\nFor CDT in Figure 4: difficulty dimension may be omitted from stat model\n")
cat("(difficulty is not known during the AUC window; see manuscript methods).\n")
