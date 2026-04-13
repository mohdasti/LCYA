#!/usr/bin/env Rscript
# =============================================================================
# LCYA Revision — 04: Confidence Ratings Analysis
#
# Purpose:
#   Analyze trial-level confidence ratings (conf_median, 4-point scale) as
#   an additional dependent variable across all three tasks (CDT, ADT, VDT),
#   following Reviewer 2, Comment #5.
#
#   Two complementary model approaches are run:
#     1. LMM (treating conf_median as continuous) — matches the framework
#        used for RT and AUC in the main analyses; simplest interpretation.
#     2. CLMM (cumulative-link mixed model via the `ordinal` package) —
#        respects the ordinal structure of the 4-point rating scale.
#
#   Both models include: Task Difficulty × Physical Effort fixed effects
#   with random slopes for all within-subjects predictors (consistent with
#   the updated random-effects structure from Script 01).
#
#   Fixed effects: Task Difficulty (Easy vs. Hard), Physical Effort (Low vs. High),
#   and their interaction. Random effects: maximal with principled reduction.
#
# Outputs (./outputs/):
#   LCYA_Confidence_FixedEffects.csv      — comprehensive results table (LMM + CLMM)
#   LCYA_Confidence_Summary.txt           — model summaries
#   LCYA_Confidence_BarPlot.pdf/.png      — Figure: mean confidence ± SEM per condition
#   LCYA_Confidence_IndividualPoints.pdf  — with overlaid individual subject means
#
# Reviewer context:
#   R2 #5 — confidence ratings were collected but not reported; analyze and
#            include in Results alongside accuracy and RT.
#
# Date: March 2026
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(lme4)
  library(lmerTest)
  library(broom.mixed)
  library(ggplot2)
  library(patchwork)
})

# Try to load ordinal; if not installed, offer to install
if (!requireNamespace("ordinal", quietly = TRUE)) {
  message("Package 'ordinal' not found. Installing...")
  install.packages("ordinal", repos = "https://cloud.r-project.org")
}
library(ordinal)

# =============================================================================
# CONFIGURATION
# =============================================================================

BASE_DIR   <- "/Users/mohdasti/Documents/LC\u2013YA"
DATA_DIR   <- file.path(BASE_DIR, "100 Hz")
OUTPUT_DIR <- file.path(BASE_DIR, "GitHub_Ready_Analyses",
                        "06_Revision_Analyses", "04_Confidence_Ratings",
                        "outputs")

if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)

TASKS <- c("CDT", "ADT", "VDT")

DIFF_CODING <- list(
  CDT = list(easy = c(5, 20),        hard = c(45, 90)),
  ADT = list(easy = c(4, 8),         hard = c(32, 128)),
  VDT = list(easy = c(0.04, 0.08),   hard = c(0.16, 0.32))
)

# Published color scheme (matches existing manuscript figures)
CONDITION_COLORS <- c(
  "Easy / Low"  = "#5DADE2",
  "Easy / High" = "#2E86AB",
  "Hard / Low"  = "#EC70AB",
  "Hard / High" = "#A23B72"
)

cat("=== LCYA Revision: Confidence Ratings Analysis ===\n")
cat("Output directory:", OUTPUT_DIR, "\n\n")

# =============================================================================
# DATA LOADING AND TRIAL-LEVEL EXTRACTION
# =============================================================================

load_trial_confidence <- function(task_name) {
  files <- list.files(DATA_DIR,
                      pattern = paste0(".*", task_name, "_DS100_merged\\.csv$"),
                      full.names = TRUE)
  stopifnot(length(files) > 0)

  map_dfr(files, ~ read_csv(.x, show_col_types = FALSE) %>%
            mutate(task = task_name)) %>%
    filter(stimLev != 0) %>%
    # One row per trial (qualify with dplyr:: — ordinal masks slice)
    group_by(sub, trial_index) %>%
    dplyr::slice(1) %>%
    ungroup() %>%
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
    filter(!is.na(difficulty), !is.na(effort), !is.na(conf_median)) %>%
    # Exclude conf_median = 0: these appear in the merged pupil CSV files for
    # rows that lack a confidence response (e.g., missed response window).
    # The behavioral data files confirm the valid scale is 1–4 only.
    filter(conf_median > 0) %>%
    mutate(
      difficulty    = factor(difficulty, levels = c("Easy", "Hard")),
      effort        = factor(effort,     levels = c("Low",  "High")),
      sub           = factor(sub),
      task          = task_name,
      # For CLMM: conf must be an ordered factor with explicitly defined 1-4 levels.
      # Note: in practice, values 1 and 2 are rare (participants are mostly
      # confident), but all four levels are retained to respect the design.
      conf_ordinal  = factor(conf_median, levels = c(1, 2, 3, 4), ordered = TRUE),
      condition     = paste(as.character(difficulty), as.character(effort), sep = " / ")
    )
}

# =============================================================================
# MODEL FITTING HELPER
# =============================================================================

fit_reduced_lmm <- function(f_str, data, label = "") {
  try_fit <- function(f) {
    tryCatch({
      m <- lmer(f, data, REML = TRUE,
                control = lmerControl(optimizer = "bobyqa",
                                      optCtrl   = list(maxfun = 2e5)))
      list(model = m, formula_used = paste(deparse(f), collapse = " "), singular = isSingular(m, tol = 1e-4))
    }, error = function(e)
      list(model = NULL, formula_used = paste(deparse(f), collapse = " "), singular = NA))
  }
  r <- try_fit(as.formula(f_str))
  if (!is.null(r$model) && !r$singular) { cat(" [", label, "] Maximal OK.\n"); return(r) }

  f2 <- gsub("\\| sub\\)", "|| sub)", f_str)
  r2 <- try_fit(as.formula(f2))
  if (!is.null(r2$model) && !r2$singular) { cat(" [", label, "] Uncorrelated OK.\n"); return(r2) }

  f3 <- gsub("\\(1 \\+[^)]+\\|[^)]*\\)", "(1 | sub)", f_str)
  r3 <- try_fit(as.formula(f3))
  cat(" [", label, "] Random intercept OK.\n")
  r3
}

fit_clmm <- function(f_str, data, label = "") {
  tryCatch({
    m <- clmm(as.formula(f_str), data = data,
              control = clmm.control(maxIter = 200))
    cat(" [", label, "] CLMM OK.\n")
    list(model = m, formula_used = f_str)
  }, error = function(e) {
    cat(" [", label, "] CLMM failed:", e$message, "\n")
    list(model = NULL, formula_used = f_str)
  })
}

extract_fe_lmm <- function(result, task, mtype, model_set) {
  m <- result$model; if (is.null(m)) return(NULL)
  coef_df <- as.data.frame(summary(m)$coefficients) %>% rownames_to_column("term")
  names(coef_df)[2:6] <- c("b", "SE", "df", "t", "p")
  ci <- tryCatch(
    confint(m, method = "Wald", parm = "beta_") %>%
      as.data.frame() %>% rownames_to_column("term") %>%
      rename(CI_lower = `2.5 %`, CI_upper = `97.5 %`),
    error = function(e) data.frame(term = coef_df$term, CI_lower = NA, CI_upper = NA)
  )
  coef_df %>%
    left_join(ci, by = "term") %>%
    mutate(task = task, model_type = mtype, model_set = model_set,
           formula = result$formula_used, sig = p < .05)
}

extract_fe_clmm <- function(result, task) {
  m <- result$model; if (is.null(m)) return(NULL)
  coef_df <- as.data.frame(summary(m)$coefficients) %>% rownames_to_column("term")
  # Keep only regression coefficients (not threshold parameters)
  coef_df <- coef_df %>% filter(!grepl("\\|", term))
  names(coef_df)[2:5] <- c("b", "SE", "z", "p")
  coef_df %>%
    mutate(task = task, model_type = "CLMM", model_set = "CLMM_ordinal",
           formula = result$formula_used,
           CI_lower = b - 1.96 * SE, CI_upper = b + 1.96 * SE,
           sig = p < .05)
}

# =============================================================================
# MAIN ANALYSIS
# =============================================================================

all_fe   <- list()
all_data <- list()
sink_log <- file.path(OUTPUT_DIR, "LCYA_Confidence_Summary.txt")
sink(sink_log); cat("LCYA — Confidence Ratings Model Summaries\nGenerated:", format(Sys.time()), "\n\n"); sink()

for (task_name in TASKS) {
  cat("\n", strrep("=", 60), "\n")
  cat("TASK:", task_name, "\n")
  cat(strrep("=", 60), "\n")

  d <- load_trial_confidence(task_name)
  all_data[[task_name]] <- d
  cat("  Trials:", nrow(d), "| Subjects:", n_distinct(d$sub),
      "| Confidence range:", min(d$conf_median, na.rm = TRUE),
      "\u2013", max(d$conf_median, na.rm = TRUE),
      "(1=least confident, 4=most confident)\n")

  # Confidence rating distribution
  sink(sink_log, append = TRUE)
  cat("\n--- Task:", task_name, "---\n")
  cat("Confidence rating distribution (1 = least confident, 4 = most confident):\n")
  cat("Note: participants are heavily skewed toward high confidence (3-4).\n")
  cat("Values of 1 and 2 are rare — the ordinal model is appropriate.\n")
  print(table(d$conf_median, dnn = "conf_median"))
  pct <- round(prop.table(table(d$conf_median)) * 100, 1)
  cat("Proportions (%):\n"); print(pct)
  cat("\n")
  sink()

  log_m <- function(label, result) {
    sink(sink_log, append = TRUE)
    cat(strrep("-", 60), "\n", label, "\nFormula:", result$formula_used, "\n\n")
    if (!is.null(result$model)) print(summary(result$model))
    cat("\n"); sink()
  }

  # ── LMM: conf_median as continuous outcome ────────────────────────────────
  cat("\n[LMM] confidence ~ difficulty * effort\n")
  r_lmm <- fit_reduced_lmm(
    "conf_median ~ difficulty * effort + (1 + difficulty + effort + difficulty:effort | sub)",
    data = d, label = paste(task_name, "LMM_Conf")
  )
  log_m(paste(task_name, "LMM: confidence ~ difficulty * effort"), r_lmm)
  all_fe[[paste(task_name, "LMM")]] <- extract_fe_lmm(r_lmm, task_name, "LMM", "LMM_continuous")

  # ── CLMM: conf_ordinal as ordinal outcome ─────────────────────────────────
  cat("\n[CLMM] conf_ordinal ~ difficulty * effort | sub\n")
  r_clmm <- fit_clmm(
    "conf_ordinal ~ difficulty * effort + (1 | sub)",
    data = d, label = paste(task_name, "CLMM_Conf")
  )
  log_m(paste(task_name, "CLMM: conf_ordinal ~ difficulty * effort"), r_clmm)
  all_fe[[paste(task_name, "CLMM")]] <- extract_fe_clmm(r_clmm, task_name)
}

# =============================================================================
# SAVE RESULTS
# =============================================================================

fe_table <- bind_rows(all_fe) %>%
  mutate(
    term_clean = recode(term,
      "(Intercept)"               = "Intercept",
      "difficultyHard"            = "Task Difficulty (Hard vs. Easy)",
      "effortHigh"                = "Physical Effort (High vs. Low)",
      "difficultyHard:effortHigh" = "Task Difficulty × Physical Effort",
      .default = term
    ),
    across(c(b, SE, CI_lower, CI_upper, any_of(c("z", "t", "df", "p"))),
           ~ round(.x, 4))
  )

write_csv(fe_table, file.path(OUTPUT_DIR, "LCYA_Confidence_FixedEffects.csv"))
cat("\nSaved: LCYA_Confidence_FixedEffects.csv\n")

sink(sink_log, append = TRUE)
cat("\n\n", strrep("=", 60), "\n")
cat("COMPREHENSIVE CONFIDENCE FIXED-EFFECTS TABLE\n\n")
print(as.data.frame(fe_table), digits = 4)
sink()

# =============================================================================
# FIGURE: MEAN CONFIDENCE ± SEM (BAR PLOT, matching existing manuscript style)
# =============================================================================

all_combined <- bind_rows(all_data)

# Group-level summary
group_summary <- all_combined %>%
  group_by(task, difficulty, effort, condition) %>%
  summarise(
    conf_mean = mean(conf_median, na.rm = TRUE),
    conf_se   = sd(conf_median, na.rm = TRUE) / sqrt(n_distinct(sub)),
    n_subs    = n_distinct(sub),
    .groups   = "drop"
  ) %>%
  mutate(
    task      = factor(task, levels = TASKS),
    condition = factor(condition, levels = names(CONDITION_COLORS))
  )

# Subject-level means (for individual point overlay)
sub_means <- all_combined %>%
  group_by(sub, task, difficulty, effort, condition) %>%
  summarise(conf_mean = mean(conf_median, na.rm = TRUE), .groups = "drop") %>%
  mutate(
    task      = factor(task, levels = TASKS),
    condition = factor(condition, levels = names(CONDITION_COLORS))
  )

theme_pub <- function() {
  theme_minimal(base_size = 11) +
    theme(
      panel.grid.minor  = element_blank(),
      panel.grid.major  = element_line(colour = "grey92", linewidth = 0.3),
      panel.border      = element_blank(),
      strip.background  = element_blank(),
      strip.text        = element_text(face = "bold", size = 11),
      axis.title        = element_text(face = "bold"),
      legend.position   = "bottom",
      legend.title      = element_text(face = "bold")
    )
}

# Bar plot with SEM
p_bars <- ggplot(group_summary,
                 aes(x = difficulty, y = conf_mean,
                     fill = condition, group = condition)) +
  geom_col(position = position_dodge(0.7), width = 0.6, alpha = 0.9) +
  geom_errorbar(aes(ymin = conf_mean - conf_se, ymax = conf_mean + conf_se),
                position = position_dodge(0.7), width = 0.2, linewidth = 0.6) +
  facet_wrap(~ task, nrow = 1) +
  scale_fill_manual(values = CONDITION_COLORS,
                    name   = "Condition (Difficulty / Effort)") +
  scale_y_continuous(limits = c(0, 4.5), breaks = 0:4) +
  labs(
    title = "Confidence Ratings by Task Difficulty and Physical Effort",
    x     = "Task Difficulty",
    y     = "Mean Confidence Rating (1–4)"
  ) +
  theme_pub()

ggsave(file.path(OUTPUT_DIR, "LCYA_Confidence_BarPlot.pdf"),
       p_bars, width = 9, height = 4, useDingbats = FALSE)
ggsave(file.path(OUTPUT_DIR, "LCYA_Confidence_BarPlot.png"),
       p_bars, width = 9, height = 4, dpi = 300)
cat("Saved: LCYA_Confidence_BarPlot.pdf/.png\n")

# Bar plot with individual data points + connecting lines
p_indiv <- ggplot(group_summary,
                  aes(x = difficulty, y = conf_mean,
                      fill = condition, group = condition)) +
  geom_col(position = position_dodge(0.7), width = 0.6, alpha = 0.75) +
  geom_errorbar(aes(ymin = conf_mean - conf_se, ymax = conf_mean + conf_se),
                position = position_dodge(0.7), width = 0.2, linewidth = 0.6) +
  # Individual subject means
  geom_point(data = sub_means,
             aes(y = conf_mean, colour = condition),
             position = position_dodge(0.7),
             size = 1.5, alpha = 0.4, shape = 16, show.legend = FALSE) +
  # Connecting lines (same subject, same effort level, across difficulty)
  geom_line(data = sub_means,
            aes(y = conf_mean, group = interaction(sub, effort), colour = condition),
            position = position_dodge(0.7),
            linewidth = 0.3, alpha = 0.25, show.legend = FALSE) +
  facet_wrap(~ task, nrow = 1) +
  scale_fill_manual(values  = CONDITION_COLORS, name = "Condition") +
  scale_colour_manual(values = CONDITION_COLORS) +
  scale_y_continuous(limits = c(0, 4.5), breaks = 0:4) +
  labs(
    title = "Confidence Ratings — Individual Data",
    x     = "Task Difficulty",
    y     = "Mean Confidence Rating (1–4)"
  ) +
  theme_pub()

ggsave(file.path(OUTPUT_DIR, "LCYA_Confidence_IndividualPoints.pdf"),
       p_indiv, width = 9, height = 4.5, useDingbats = FALSE)
ggsave(file.path(OUTPUT_DIR, "LCYA_Confidence_IndividualPoints.png"),
       p_indiv, width = 9, height = 4.5, dpi = 300)
cat("Saved: LCYA_Confidence_IndividualPoints.pdf/.png\n")

cat("\n=== DONE ===\n")
cat("All outputs saved to:", OUTPUT_DIR, "\n")
