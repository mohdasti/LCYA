#!/usr/bin/env Rscript
# =============================================================================
# LCYA Revision — 03: Continuous Grip Force as Trial-Level Predictor
#
# Purpose:
#   Use actual trial-by-trial grip force (gf_trPer, as proportion of MVC)
#   as a continuous predictor in mixed-effects models for both behavioral
#   outcomes (accuracy, RT) and pupil response (Total AUC). This tests for
#   a graded dose-response relationship between physical exertion and task
#   outcomes — a stronger test than categorical Low/High labels.
#
#   Additionally, trial-level log RT is used as a predictor in the pupil
#   models to test whether moment-to-moment variation in decision difficulty
#   is associated with pupillary arousal.
#
#   These analyses address the "motor artifact" concern: if the pupil effect
#   scales continuously with grip force (rather than being binary), this
#   provides evidence for a graded arousal response rather than a non-specific
#   motor artifact.
#
# Model set:
#   A. GRADED GRIP FORCE MODELS (behavioral outcomes):
#      iscorr  ~ difficulty * gf_scaled + (1 + difficulty + gf_scaled | sub)  [GLMM]
#      log_rt  ~ difficulty * gf_scaled + (1 + difficulty + gf_scaled | sub)  [LMM]
#
#   B. GRADED GRIP FORCE MODELS (pupil outcome):
#      Total_AUC ~ difficulty * gf_scaled + (1 + difficulty + gf_scaled | sub)  [LMM]
#      (CDT: Total_AUC ~ gf_scaled + (1 + gf_scaled | sub))
#
#   C. GRADED MODEL WITHIN HIGH-EFFORT TRIALS ONLY (measured force):
#      Models A–B use instructed target force (gf_trPer → gf_scaled).
#      Model C uses measured grip AUC / MVC (auc_rel_mvc → auc_scaled), z-scored
#      within High-effort trials only, so the slope is interpretable as pupil
#      change per SD of *actual* exerted force when gf_trPer is fixed at 0.40.
#      CDT: Total_AUC ~ auc_scaled + (1 + auc_scaled | sub)
#      ADT/VDT: Total_AUC ~ difficulty * auc_scaled + (1 + difficulty + auc_scaled | sub)
#
#   D. RT AS COGNITIVE EFFORT PROXY IN PUPIL MODELS:
#      Total_AUC ~ log_rt_scaled * effort + (1 + log_rt_scaled + effort | sub)
#      (Tests whether faster/slower decisions, as a proxy for decision
#       difficulty, predict pupil arousal above and beyond effort level)
#
# Outputs (./outputs/):
#   LCYA_GripForce_FixedEffects.csv   — comprehensive results table
#   LCYA_GripForce_Summary.txt        — model summaries
#   LCYA_GripForce_ModelC_SanityChecks.txt — Model C variance / correlation diagnostics
#   LCYA_GripForce_DosePlot.pdf       — scatterplot: gf vs Total AUC (subject×effort means)
#   LCYA_GripForce_DosePlot_TrialLevel.pdf — same axes, one point per trial
#   LCYA_GripForce_ModelC_HighOnly_aucRelMVC.pdf — measured auc_rel_mvc vs Total AUC (High only)
#   LCYA_RT_Pupil_Plot.pdf            — scatterplot: RT vs Total AUC per task
#
# Reviewer context:
#   R1 Major #3 — trial-by-trial grip force as continuous predictor;
#                 RT as cognitive effort proxy in pupil models;
#                 binary vs. graded motor artifact test
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

# =============================================================================
# CONFIGURATION
# =============================================================================

BASE_DIR   <- "/Users/mohdasti/Documents/LC\u2013YA"
DATA_DIR   <- file.path(BASE_DIR, "100 Hz")
OUTPUT_DIR <- file.path(BASE_DIR, "GitHub_Ready_Analyses",
                        "06_Revision_Analyses", "03_Continuous_Grip_Force",
                        "outputs")

if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)

TASKS <- c("CDT", "ADT", "VDT")

DIFF_CODING <- list(
  CDT = list(easy = c(5, 20),        hard = c(45, 90)),
  ADT = list(easy = c(4, 8),         hard = c(32, 128)),
  VDT = list(easy = c(0.04, 0.08),   hard = c(0.16, 0.32))
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

cat("=== LCYA Revision: Continuous Grip Force Models ===\n")
cat("Output directory:", OUTPUT_DIR, "\n\n")

# =============================================================================
# SHARED HELPERS (mirrors Script 01)
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
  ts <- t[ok]; ys <- y[ok]
  ord <- order(ts)
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
      s2_rel   = (.data[[paste0("t_", cfg$s2_label)]] - squeeze_time),
      resp_rel = (t_Response - squeeze_time)
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
    group_by(sub, trial_index, task, difficulty, effort,
             stimLev, isStrength, gf_trPer, auc_rel_mvc, iscorr, resp1RT, conf_median,
             s2_rel, resp_rel) %>%
    summarise(
      b0 = mean(pupil[t_sq >= -0.5 & t_sq < 0], na.rm = TRUE),
      Total_AUC = calc_auc_trap(t_sq, pupil - b0, cfg$total_start, first(resp_rel)),
      .groups = "drop"
    ) %>%
    mutate(
      difficulty = factor(difficulty, levels = c("Easy", "Hard")),
      effort     = factor(effort,     levels = c("Low",  "High")),
      sub        = factor(sub),
      log_rt     = log(resp1RT)
    )
}

fit_reduced <- function(f_str, data, family = NULL, label = "") {
  try_fit <- function(f) {
    tryCatch({
      ctrl_l <- lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 2e5))
      ctrl_g <- glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 2e5))
      m <- if (is.null(family)) lmer(f, data, REML = TRUE, control = ctrl_l)
           else                  glmer(f, data, family = family, control = ctrl_g)
      list(model = m, formula_used = paste(deparse(f), collapse = " "), singular = isSingular(m, tol = 1e-4))
    }, error = function(e)
      list(model = NULL, formula_used = paste(deparse(f), collapse = " "), singular = NA, error = e$message))
  }
  r <- try_fit(as.formula(f_str))
  if (!is.null(r$model) && !r$singular) { cat(" [", label, "] OK.\n"); return(r) }

  f2 <- gsub("\\| sub\\)", "|| sub)", f_str)
  r2 <- try_fit(as.formula(f2))
  if (!is.null(r2$model) && !r2$singular) { cat(" [", label, "] Uncorrelated slopes OK.\n"); return(r2) }

  f3 <- gsub("\\(1 \\+[^)]+\\|[^)]*\\)", "(1 | sub)", f_str)
  r3 <- try_fit(as.formula(f3))
  cat(" [", label, "] Random intercept OK.\n")
  r3
}

extract_fe <- function(result, task, outcome, mtype, model_set) {
  m <- result$model
  if (is.null(m)) return(NULL)
  coef_df <- as.data.frame(summary(m)$coefficients) %>% rownames_to_column("term")
  if (mtype == "GLMM") {
    names(coef_df)[2:5] <- c("b", "SE", "z", "p"); coef_df$t <- NA; coef_df$df <- NA
  } else {
    names(coef_df)[2:6] <- c("b", "SE", "df", "t", "p"); coef_df$z <- NA
  }
  ci <- tryCatch(
    confint(m, method = "Wald", parm = "beta_") %>%
      as.data.frame() %>% rownames_to_column("term") %>%
      rename(CI_lower = `2.5 %`, CI_upper = `97.5 %`),
    error = function(e) data.frame(term = coef_df$term, CI_lower = NA, CI_upper = NA)
  )
  coef_df %>%
    left_join(ci, by = "term") %>%
    mutate(task = task, outcome = outcome, model_type = mtype,
           model_set = model_set, formula = result$formula_used, sig = p < .05)
}

# =============================================================================
# MAIN ANALYSIS LOOP
# =============================================================================

all_fe   <- list()
sink_log <- file.path(OUTPUT_DIR, "LCYA_GripForce_Summary.txt")
sink(sink_log); cat("LCYA — Continuous Grip Force Model Summaries\nGenerated:", format(Sys.time()), "\n\n"); sink()

sanity_log <- file.path(OUTPUT_DIR, "LCYA_GripForce_ModelC_SanityChecks.txt")
writeLines(
  c(
    "LCYA Model C — auc_rel_mvc within High-effort trials (z-scored within High only)",
    paste("Generated:", format(Sys.time())),
    strrep("=", 60),
    ""
  ),
  con = sanity_log
)

all_trial_data <- list()  # for visualisation

for (task_name in TASKS) {
  cat("\n", strrep("=", 60), "\n")
  cat("TASK:", task_name, "\n")
  cat(strrep("=", 60), "\n")

  raw <- load_raw(task_name)
  cat("  Computing trial-level AUC...\n")
  d <- compute_trial_auc(raw, TASK_CFG[[task_name]]) %>%
    filter(!is.na(Total_AUC), !is.na(gf_trPer), !is.na(resp1RT)) %>%
    mutate(
      gf_scaled     = as.numeric(scale(gf_trPer)),   # instructed force (all trials)
      log_rt_scaled = as.numeric(scale(log_rt))
    )

  # Sanity: auc_rel_mvc must be single-valued per trial in source long-format data
  auc_consistency <- raw %>%
    group_by(sub, trial_index) %>%
    summarise(
      n_distinct_auc = dplyr::n_distinct(auc_rel_mvc, na.rm = TRUE),
      any_non_na     = any(!is.na(auc_rel_mvc)),
      .groups = "drop"
    )
  bad_trials <- auc_consistency %>% filter(n_distinct_auc > 1)
  if (nrow(bad_trials) > 0) {
    stop("Inconsistent auc_rel_mvc within trial for task ", task_name, ": ",
         nrow(bad_trials), " trial(s).")
  }

  all_trial_data[[task_name]] <- d
  cat("  Trials:", nrow(d), "| Subjects:", n_distinct(d$sub), "\n")

  log_append <- function(label, result) {
    sink(sink_log, append = TRUE)
    cat(strrep("-", 60), "\n", label, "\nFormula:", result$formula_used, "\n\n")
    if (!is.null(result$model)) print(summary(result$model))
    cat("\n"); sink()
  }

  # ── A. Grip Force → Accuracy (GLMM) ──────────────────────────────────────
  cat("\n[A] gf_scaled → Accuracy\n")
  r <- fit_reduced(
    "iscorr ~ difficulty * gf_scaled + (1 + difficulty + gf_scaled | sub)",
    data = d, family = binomial(), label = paste(task_name, "Acc~GF")
  )
  log_append(paste(task_name, "Model A: Accuracy ~ GF"), r)
  all_fe[[paste(task_name, "A_Accuracy")]] <- extract_fe(r, task_name, "Accuracy", "GLMM", "A_GF_Behavioral")

  # ── A. Grip Force → RT (LMM) ─────────────────────────────────────────────
  cat("\n[A] gf_scaled → RT\n")
  r <- fit_reduced(
    "log_rt ~ difficulty * gf_scaled + (1 + difficulty + gf_scaled | sub)",
    data = d, label = paste(task_name, "RT~GF")
  )
  log_append(paste(task_name, "Model A: RT ~ GF"), r)
  all_fe[[paste(task_name, "A_RT")]] <- extract_fe(r, task_name, "RT_log", "LMM", "A_GF_Behavioral")

  # ── B. Grip Force → Total AUC (LMM, full model) ──────────────────────────
  cat("\n[B] gf_scaled → Total AUC (full trials)\n")
  b_formula <- if (task_name == "CDT") {
    "Total_AUC ~ gf_scaled + (1 + gf_scaled | sub)"
  } else {
    "Total_AUC ~ difficulty * gf_scaled + (1 + difficulty + gf_scaled | sub)"
  }
  r <- fit_reduced(b_formula, data = d, label = paste(task_name, "AUC~GF"))
  log_append(paste(task_name, "Model B: Total AUC ~ GF"), r)
  all_fe[[paste(task_name, "B_TotalAUC")]] <- extract_fe(r, task_name, "Total_AUC", "LMM", "B_GF_Pupil")

  # ── C. Measured grip (auc_rel_mvc) within High-effort trials only ─────────
  # gf_trPer is constant (0.40) on High trials; auc_rel_mvc carries trial-wise
  # variation in actual force. Scale within High subset only (mean 0, SD 1).
  cat("\n[C] auc_scaled (measured AUC/MVC) → Total AUC (High effort only)\n")
  d_high <- d %>%
    filter(effort == "High", !is.na(auc_rel_mvc)) %>%
    mutate(auc_scaled = as.numeric(scale(auc_rel_mvc)))

  # --- Sanity checks (console + log file) ---
  sanity_lines <- c(
    sprintf("Task %s — Model C diagnostics (High-effort trials only)", task_name),
    sprintf("  n trials: %d | n subjects: %d", nrow(d_high), n_distinct(d_high$sub)),
    sprintf("  gf_trPer: n_unique = %d | sd = %.6f (expect ~0, all High = 0.40)",
            dplyr::n_distinct(d_high$gf_trPer), stats::sd(d_high$gf_trPer, na.rm = TRUE)),
    sprintf("  auc_rel_mvc: min = %.4f | max = %.4f | sd = %.6f (expect sd > 0)",
            min(d_high$auc_rel_mvc, na.rm = TRUE), max(d_high$auc_rel_mvc, na.rm = TRUE),
            stats::sd(d_high$auc_rel_mvc, na.rm = TRUE)),
    sprintf("  auc_scaled: mean = %.6f | sd = %.6f (expect ~0 and ~1)",
            mean(d_high$auc_scaled, na.rm = TRUE), stats::sd(d_high$auc_scaled, na.rm = TRUE)),
    sprintf("  cor(Total_AUC, auc_rel_mvc) [trial-level, High]: %.4f",
            stats::cor(d_high$Total_AUC, d_high$auc_rel_mvc, use = "complete.obs"))
  )
  cat(paste(sanity_lines, collapse = "\n"), "\n")
  cat(paste(c(sanity_lines, ""), collapse = "\n"), file = sanity_log, append = TRUE)

  if (nrow(d_high) > 50 && n_distinct(d_high$sub) > 5 &&
      stats::sd(d_high$auc_rel_mvc, na.rm = TRUE) > .Machine$double.eps) {
    r <- fit_reduced(
      if (task_name == "CDT") "Total_AUC ~ auc_scaled + (1 + auc_scaled | sub)"
      else "Total_AUC ~ difficulty * auc_scaled + (1 + difficulty + auc_scaled | sub)",
      data = d_high, label = paste(task_name, "AUC~aucRelMVC_HighOnly")
    )
    log_append(paste(task_name, "Model C: Total AUC ~ auc_rel_mvc scaled (High only)"), r)
    all_fe[[paste(task_name, "C_TotalAUC_HighOnly")]] <- extract_fe(
      r, task_name, "Total_AUC_HighOnly", "LMM", "C_GF_Pupil_HighOnly_aucRelMVC"
    )
  } else {
    cat("  Skipping C: insufficient trials/subjects or zero variance in auc_rel_mvc.\n")
  }

  # ── D. RT as cognitive effort proxy in pupil model ────────────────────────
  # Note: log_rt_scaled is used as a PREDICTOR here (not as an outcome).
  # This tests whether moment-to-moment variation in decision time is
  # associated with pupillary arousal, controlling for physical effort level.
  cat("\n[D] log_rt_scaled → Total AUC (RT as cognitive effort proxy)\n")
  r <- fit_reduced(
    "Total_AUC ~ log_rt_scaled * effort + (1 + log_rt_scaled + effort | sub)",
    data = d, label = paste(task_name, "AUC~RT")
  )
  log_append(paste(task_name, "Model D: Total AUC ~ log_RT × effort"), r)
  all_fe[[paste(task_name, "D_AUC_RT")]] <- extract_fe(
    r, task_name, "Total_AUC_RTpredictor", "LMM", "D_RT_Pupil"
  )
}

# =============================================================================
# SAVE RESULTS TABLE
# =============================================================================

fe_table <- bind_rows(all_fe) %>%
  mutate(across(c(b, SE, CI_lower, CI_upper, z, t, df, p), ~ round(.x, 4)))

write_csv(fe_table, file.path(OUTPUT_DIR, "LCYA_GripForce_FixedEffects.csv"))
cat("\nSaved: LCYA_GripForce_FixedEffects.csv\n")

sink(sink_log, append = TRUE)
cat("\n\n", strrep("=", 60), "\n")
cat("COMPREHENSIVE FIXED-EFFECTS TABLE\n\n")
print(as.data.frame(fe_table), digits = 4)
sink()

# =============================================================================
# VISUALISATION: GRIP FORCE vs TOTAL AUC (dose-response scatterplot)
# =============================================================================

all_trial_combined <- bind_rows(all_trial_data) %>%
  mutate(task = factor(task, levels = TASKS)) # facet order: CDT → ADT → VDT

subject_means_gf <- all_trial_combined %>%
  group_by(sub, task, effort) %>%
  summarise(
    mean_gf  = mean(gf_trPer,  na.rm = TRUE),
    mean_auc = mean(Total_AUC, na.rm = TRUE),
    .groups  = "drop"
  )

p_gf_dose <- ggplot(subject_means_gf,
                    aes(x = mean_gf, y = mean_auc, colour = effort)) +
  geom_point(alpha = 0.6, size = 2) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 0.8) +
  facet_wrap(~ task, scales = "free_y") +
  scale_colour_manual(
    values = c("Low" = "#5DADE2", "High" = "#2E86AB"),
    name   = "Effort Level"
  ) +
  labs(
    title    = "Dose-Response: Grip Force vs. Total AUC",
    subtitle = "Subject-condition means. Lines = OLS fit. Tests graded vs. binary pupil response.",
    x        = "Mean Grip Force (proportion MVC)",
    y        = "Mean Total AUC"
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

ggsave(file.path(OUTPUT_DIR, "LCYA_GripForce_DosePlot.pdf"),
       p_gf_dose, width = 9, height = 4, useDingbats = FALSE)
ggsave(file.path(OUTPUT_DIR, "LCYA_GripForce_DosePlot.png"),
       p_gf_dose, width = 9, height = 4, dpi = 300)
cat("Saved: LCYA_GripForce_DosePlot.pdf/.png\n")

# Trial-level dose plot (same variables as above, no aggregation across trials)
trial_gf_auc <- all_trial_combined %>%
  filter(!is.na(gf_trPer), !is.na(Total_AUC))

p_gf_dose_trials <- ggplot(trial_gf_auc,
                           aes(x = gf_trPer, y = Total_AUC, colour = effort)) +
  geom_point(alpha = 0.15, size = 0.5, stroke = 0) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 0.8) +
  facet_wrap(~ task, scales = "free_y") +
  scale_colour_manual(
    values = c("Low" = "#5DADE2", "High" = "#2E86AB"),
    name   = "Effort Level"
  ) +
  labs(
    title    = "Dose-Response: Grip Force vs. Total AUC (trial level)",
    subtitle = "One point per trial. Lines = OLS fit within each effort level.",
    x        = "Grip Force (proportion MVC)",
    y        = "Total AUC"
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

ggsave(file.path(OUTPUT_DIR, "LCYA_GripForce_DosePlot_TrialLevel.pdf"),
       p_gf_dose_trials, width = 9, height = 4, useDingbats = FALSE)
ggsave(file.path(OUTPUT_DIR, "LCYA_GripForce_DosePlot_TrialLevel.png"),
       p_gf_dose_trials, width = 9, height = 4, dpi = 300)
cat("Saved: LCYA_GripForce_DosePlot_TrialLevel.pdf/.png\n")

# Model C diagnostic: measured grip (AUC/MVC) vs pupil, High-effort trials only
trial_c_high <- all_trial_combined %>%
  filter(effort == "High", !is.na(auc_rel_mvc), !is.na(Total_AUC))

if (nrow(trial_c_high) > 0) {
  p_model_c <- ggplot(trial_c_high,
                      aes(x = auc_rel_mvc, y = Total_AUC)) +
    geom_point(alpha = 0.12, size = 0.4) +
    geom_smooth(method = "lm", se = TRUE, linewidth = 0.8, colour = "#2E86AB") +
    facet_wrap(~ task, scales = "free_y") +
    labs(
      title    = "Model C diagnostic: measured grip (auc_rel_mvc) vs. Total AUC",
      subtitle = "High-effort trials only (instructed gf_trPer = 0.40). Trial-level points.",
      x        = expression("Grip AUC / MVC (" * auc[rel] * ")"),
      y        = "Total AUC (pupil)"
    ) +
    theme_minimal(base_size = 11) +
    theme(panel.grid.minor = element_blank())

  ggsave(file.path(OUTPUT_DIR, "LCYA_GripForce_ModelC_HighOnly_aucRelMVC.pdf"),
         p_model_c, width = 9, height = 4, useDingbats = FALSE)
  ggsave(file.path(OUTPUT_DIR, "LCYA_GripForce_ModelC_HighOnly_aucRelMVC.png"),
         p_model_c, width = 9, height = 4, dpi = 300)
  cat("Saved: LCYA_GripForce_ModelC_HighOnly_aucRelMVC.pdf/.png\n")
}

# =============================================================================
# VISUALISATION: RT vs TOTAL AUC (RT as cognitive effort proxy)
# =============================================================================

subject_means_rt <- all_trial_combined %>%
  group_by(sub, task, effort, difficulty) %>%
  summarise(
    mean_rt  = mean(resp1RT,   na.rm = TRUE),
    mean_auc = mean(Total_AUC, na.rm = TRUE),
    .groups  = "drop"
  )

p_rt_pupil <- ggplot(subject_means_rt,
                     aes(x = log(mean_rt), y = mean_auc,
                         colour = difficulty, shape = effort)) +
  geom_point(alpha = 0.6, size = 2) +
  geom_smooth(
    data = subject_means_rt,
    inherit.aes = FALSE,
    mapping = aes(x = log(mean_rt), y = mean_auc, group = effort),
    method = "lm", se = FALSE,
    colour = "grey40", linewidth = 0.7, linetype = "dashed"
  ) +
  facet_wrap(~ task, scales = "free_y") +
  scale_colour_manual(
    values = c("Easy" = "#5DADE2", "Hard" = "#A23B72"),
    name   = "Task Difficulty"
  ) +
  scale_shape_manual(values = c("Low" = 16, "High" = 17), name = "Effort") +
  labs(
    title    = "RT as Cognitive Effort Proxy: log RT vs. Total AUC",
    subtitle = "Subject-condition means. Dashed lines per effort level.",
    x        = "Mean log Reaction Time",
    y        = "Mean Total AUC"
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

ggsave(file.path(OUTPUT_DIR, "LCYA_RT_Pupil_Plot.pdf"),
       p_rt_pupil, width = 9, height = 4, useDingbats = FALSE)
ggsave(file.path(OUTPUT_DIR, "LCYA_RT_Pupil_Plot.png"),
       p_rt_pupil, width = 9, height = 4, dpi = 300)
cat("Saved: LCYA_RT_Pupil_Plot.pdf/.png\n")

cat("\n=== DONE ===\n")
cat("All outputs saved to:", OUTPUT_DIR, "\n")
