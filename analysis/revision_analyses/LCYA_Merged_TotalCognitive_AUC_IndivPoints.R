#!/usr/bin/env Rscript
# =============================================================================
# LCYA — Merged Total AUC + Cognitive AUC Figure with Individual Data Points
#
# Purpose:
#   Produce a single 2-row figure combining:
#     Row 1 — Total AUC (CDT, ADT, VDT)
#     Row 2 — Cognitive AUC (ADT, VDT only; CDT excluded because the probe is
#              presented during the response window, making a cognitive window
#              ill-defined)
#
#   Both rows include jittered individual participant points (N=38) overlaid
#   on group-mean bars ± SE, with within-subject connecting lines across
#   difficulty levels for the same effort condition.
#
# Output (./outputs/):
#   Figure4_Merged_Total_Cognitive_AUC_IndivPoints.pdf/.png
#
# Date: May 2026
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
DATA_DIR   <- "/Users/mohdasti/Documents/GitHub/LCYA/LC\u2013YA/100 Hz"
OUTPUT_DIR <- file.path(BASE_DIR, "GitHub_Ready_Analyses",
                        "06_Revision_Analyses", "05_Updated_Figures", "outputs")

if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)

TASKS <- c("CDT", "ADT", "VDT")

DIFF_CODING <- list(
  CDT = list(easy = c(45, 90),        hard = c(5, 20)),
  ADT = list(easy = c(32, 128),       hard = c(4, 8)),
  VDT = list(easy = c(0.16, 0.32),    hard = c(0.04, 0.08))
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

CONDITION_COLORS <- c(
  "Easy / Low"  = "#5DADE2",
  "Easy / High" = "#2E86AB",
  "Hard / Low"  = "#EC70AB",
  "Hard / High" = "#A23B72"
)

cat("=== LCYA: Merged Total + Cognitive AUC Figure (Individual Points) ===\n")
cat("Output directory:", OUTPUT_DIR, "\n\n")

# =============================================================================
# HELPERS
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
      Total_AUC     = calc_auc_trap(t_sq, pupil,        cfg$total_start, first(resp_rel)),
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
# LOAD DATA
# =============================================================================

cat("Loading and computing AUC for all tasks...\n")
auc_all <- list()
for (task_name in TASKS) {
  cat("  Processing", task_name, "...\n")
  raw <- load_raw(task_name)
  auc_all[[task_name]] <- compute_trial_auc(raw, TASK_CFG[[task_name]])
}

auc_combined <- bind_rows(auc_all) %>%
  mutate(task      = factor(task,      levels = TASKS),
         condition = factor(condition, levels = names(CONDITION_COLORS)))

cat("Data loaded.\n\n")

# =============================================================================
# THEME
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

# =============================================================================
# ROW 1 — TOTAL AUC (CDT, ADT, VDT)
# =============================================================================

cat("Building Row 1: Total AUC (all 3 tasks)...\n")

sub_total <- auc_combined %>%
  filter(!is.na(Total_AUC)) %>%
  group_by(sub, task, difficulty, effort, condition) %>%
  summarise(value = mean(Total_AUC, na.rm = TRUE), .groups = "drop") %>%
  mutate(condition = factor(condition, levels = names(CONDITION_COLORS)))

grp_total <- sub_total %>%
  group_by(task, difficulty, effort, condition) %>%
  summarise(
    auc_mean = mean(value, na.rm = TRUE),
    auc_se   = sd(value,   na.rm = TRUE) / sqrt(n()),
    .groups  = "drop"
  ) %>%
  mutate(condition = factor(condition, levels = names(CONDITION_COLORS)))

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
  labs(x = NULL, y = "Total AUC (a.u.)") +
  theme_pub()

# =============================================================================
# ROW 2 — COGNITIVE AUC (ADT, VDT only)
# =============================================================================

cat("Building Row 2: Cognitive AUC (ADT + VDT)...\n")

cog_tasks <- c("ADT", "VDT")

sub_cog <- auc_combined %>%
  filter(task %in% cog_tasks, !is.na(Cognitive_AUC)) %>%
  group_by(sub, task, difficulty, effort, condition) %>%
  summarise(value = mean(Cognitive_AUC, na.rm = TRUE), .groups = "drop") %>%
  mutate(condition = factor(condition, levels = names(CONDITION_COLORS)))

grp_cog <- sub_cog %>%
  group_by(task, difficulty, effort, condition) %>%
  summarise(
    auc_mean = mean(value, na.rm = TRUE),
    auc_se   = sd(value,   na.rm = TRUE) / sqrt(n()),
    .groups  = "drop"
  ) %>%
  mutate(condition = factor(condition, levels = names(CONDITION_COLORS)))

cog_all_vals <- c(sub_cog$value,
                  grp_cog$auc_mean - grp_cog$auc_se,
                  grp_cog$auc_mean + grp_cog$auc_se)
cog_ylim <- range(cog_all_vals, na.rm = TRUE)
cog_buf  <- diff(cog_ylim) * 0.05
cog_ylim <- cog_ylim + c(-cog_buf, cog_buf)

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
  coord_cartesian(ylim = cog_ylim) +
  labs(
    x = "Task Difficulty",
    y = "Cognitive AUC (a.u.)",
    caption = "CDT excluded from Cognitive AUC: probe is presented during the response window."
  ) +
  theme_pub() +
  theme(plot.caption = element_text(size = 8, colour = "grey50", hjust = 0))

# =============================================================================
# COMBINE & SAVE
# =============================================================================

cat("Combining panels and saving...\n")

# Row 2 has only 2 facets (ADT, VDT). A plot_spacer() fills the CDT slot so
# the ADT and VDT cognitive panels sit directly beneath their Total AUC
# counterparts. widths = c(1, 2) gives the spacer 1/3 and p_cog 2/3 of the
# row width, matching the three equal-width facets above.
bottom_row <- (plot_spacer() | p_cog) +
  plot_layout(widths = c(1, 2))

fig_merged <- (p_total / bottom_row) +
  plot_layout(
    guides  = "collect",
    heights = c(1, 1)
  ) &
  theme(legend.position = "bottom")

out_base <- file.path(OUTPUT_DIR, "Figure4_Merged_Total_Cognitive_AUC_IndivPoints")

ggsave(paste0(out_base, ".pdf"),
       fig_merged, width = 10, height = 8, useDingbats = FALSE)
ggsave(paste0(out_base, ".png"),
       fig_merged, width = 10, height = 8, dpi = 300)

cat("Saved: Figure4_Merged_Total_Cognitive_AUC_IndivPoints.pdf/.png\n")
cat("\n=== DONE ===\n")
cat("Output: ", out_base, ".png/.pdf\n", sep = "")
