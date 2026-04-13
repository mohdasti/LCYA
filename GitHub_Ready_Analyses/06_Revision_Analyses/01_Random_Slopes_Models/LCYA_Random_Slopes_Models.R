#!/usr/bin/env Rscript
# =============================================================================
# LCYA Revision — 01: Random Slopes Mixed-Effects Models
#
# Purpose:
#   Re-run all GLMMs (accuracy) and LMMs (RT, Total AUC, Cognitive AUC) at the
#   TRIAL LEVEL with maximal random effects (Barr et al., 2013). If maximal
#   models fail to converge, apply principled reduction (Bates et al., 2015;
#   Brauer & Curtin, 2018): first remove correlation parameters (|| syntax),
#   then drop slopes with the lowest estimated variance.
#
#   Also exports a comprehensive fixed-effects table (b, SE, 95% CI, z/t, p)
#   for ALL effects — including all non-significant ones — to satisfy
#   Reviewer 1, Major #2 and Minor #3.
#
# Outputs (./outputs/):
#   LCYA_FixedEffects_AllModels.csv      — comprehensive results table
#   LCYA_RandomEffects_Structure.csv     — final RE structure per model
#   LCYA_Model_Summaries.txt             — full lme4 summaries
#
# Reviewer context:
#   R1 Major #2  — comprehensive reporting of all fixed effects with CI
#   R1 Minor #3  — random slopes for all within-subjects predictors
#
# Date: March 2026
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(lme4)
  library(lmerTest)
  library(broom.mixed)
})

# =============================================================================
# CONFIGURATION
# =============================================================================

BASE_DIR   <- "/Users/mohdasti/Documents/LC\u2013YA"
DATA_DIR   <- file.path(BASE_DIR, "100 Hz")
OUTPUT_DIR <- file.path(BASE_DIR, "GitHub_Ready_Analyses",
                        "06_Revision_Analyses", "01_Random_Slopes_Models", "outputs")

if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)

TASKS <- c("CDT", "ADT", "VDT")

# Difficulty stim-level coding — follows existing pipeline convention
DIFF_CODING <- list(
  CDT = list(easy = c(5, 20),           hard = c(45, 90)),
  ADT = list(easy = c(4, 8),            hard = c(32, 128)),
  VDT = list(easy = c(0.04, 0.08),      hard = c(0.16, 0.32))
)

# Task-specific timing parameters for AUC computation
TASK_CFG <- list(
  CDT = list(
    b2b_dur      = 0.5,   cog_latency  = 0.3,
    total_start  = 0,
    s2_median    = 4.39,  resp_median  = 6.08,
    s2_label     = "Arrow",
    resp_label   = "Response",  conf_label = "Confidence"
  ),
  ADT = list(
    b2b_dur      = 0.5,   cog_latency  = 0.3,
    total_start  = 0,
    s2_median    = 3.78,  resp_median  = 5.49,
    s2_label     = "Stimulus",
    resp_label   = "Response",  conf_label = "Confidence"
  ),
  VDT = list(
    b2b_dur      = 0.5,   cog_latency  = 0.3,
    total_start  = 0,
    s2_median    = 3.78,  resp_median  = 5.49,
    s2_label     = "Stimulus",
    resp_label   = "Response",  conf_label = "Confidence"
  )
)

cat("=== LCYA Revision: Random Slopes Mixed-Effects Models ===\n")
cat("Output directory:", OUTPUT_DIR, "\n\n")

# =============================================================================
# HELPER: DATA LOADING
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

# =============================================================================
# HELPER: EXTRACT TRIAL-LEVEL BEHAVIORAL DATA
# (one row per trial from the time-series merged files)
# =============================================================================

trial_behavioral <- function(raw) {
  raw %>%
    group_by(sub, trial_index) %>%
    slice(1) %>%
    ungroup() %>%
    filter(!is.na(resp1RT), resp1RT > 0) %>%
    mutate(
      difficulty = factor(difficulty, levels = c("Easy", "Hard")),
      effort     = factor(effort,     levels = c("Low",  "High")),
      sub        = factor(sub),
      log_rt     = log(resp1RT)
    )
}

# =============================================================================
# HELPER: TRIAL-LEVEL AUC FROM TIME SERIES
# =============================================================================

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
    pivot_wider(names_from  = duration_label,
                values_from = evt_time,
                names_prefix = "t_")

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
             stimLev, isStrength, gf_trPer,
             iscorr, resp1RT, conf_median,
             s2_rel, resp_rel) %>%
    summarise(
      b0  = mean(pupil[t_sq >= -0.5 & t_sq < 0],   na.rm = TRUE),
      b2b = mean(pupil[t_sq >= (first(s2_rel) - cfg$b2b_dur) &
                         t_sq <  first(s2_rel)],     na.rm = TRUE),
      Total_AUC    = calc_auc_trap(t_sq, pupil - b0,
                                   cfg$total_start, first(resp_rel)),
      Cognitive_AUC = calc_auc_trap(t_sq, pupil - b2b,
                                    first(s2_rel) + cfg$cog_latency,
                                    first(resp_rel)),
      .groups = "drop"
    ) %>%
    mutate(
      difficulty = factor(difficulty, levels = c("Easy", "Hard")),
      effort     = factor(effort,     levels = c("Low",  "High")),
      sub        = factor(sub)
    )
}

# =============================================================================
# HELPER: FIT MODEL WITH PRINCIPLED REDUCTION ON CONVERGENCE FAILURE
# =============================================================================

fit_reduced <- function(f_str, data, family = NULL, label = "") {
  try_fit <- function(f) {
    tryCatch({
      ctrl_lmer  <- lmerControl(optimizer  = "bobyqa",
                                optCtrl    = list(maxfun = 2e5))
      ctrl_glmer <- glmerControl(optimizer = "bobyqa",
                                 optCtrl   = list(maxfun = 2e5))
      m <- if (is.null(family)) {
        lmer(f, data = data, REML = TRUE, control = ctrl_lmer)
      } else {
        glmer(f, data = data, family = family, control = ctrl_glmer)
      }
      list(model = m, formula_used = paste(deparse(f), collapse = " "),
           singular = isSingular(m, tol = 1e-4))
    }, error = function(e) {
      list(model = NULL, formula_used = paste(deparse(f), collapse = " "),
           singular = NA, error = e$message)
    })
  }

  # Step 1: maximal (correlated)
  r <- try_fit(as.formula(f_str))
  if (!is.null(r$model) && !r$singular) {
    cat("  [", label, "] Maximal model OK.\n")
    return(r)
  }
  cat("  [", label, "] Maximal failed/singular; trying uncorrelated slopes...\n")

  # Step 2: uncorrelated slopes (|| syntax)
  f_uncor <- gsub("\\(1 \\+", "(1 +", f_str)   # keep formatting
  f_uncor <- gsub("\\| sub\\)", "|| sub)", f_uncor)
  r2 <- try_fit(as.formula(f_uncor))
  if (!is.null(r2$model) && !r2$singular) {
    cat("  [", label, "] Uncorrelated slopes OK.\n")
    return(r2)
  }
  cat("  [", label, "] Uncorrelated slopes failed/singular; falling back to random intercept.\n")

  # Step 3: random intercept only
  f_int <- gsub("\\(1 \\+[^)]+\\|[^)]*\\)", "(1 | sub)", f_str)
  f_int <- gsub("\\(1 \\+[^)]+\\|\\|[^)]*\\)", "(1 | sub)", f_int)
  r3 <- try_fit(as.formula(f_int))
  if (!is.null(r3$model)) {
    cat("  [", label, "] Random intercept OK.\n")
    return(r3)
  }

  stop("[", label, "] All fitting attempts failed.")
}

# =============================================================================
# HELPER: EXTRACT COMPREHENSIVE FIXED-EFFECTS TABLE
# =============================================================================

extract_fe <- function(result, task, outcome, mtype) {
  m <- result$model
  if (is.null(m)) return(NULL)

  coef_df <- as.data.frame(summary(m)$coefficients) %>%
    rownames_to_column("term")

  # Standardise column names across GLMM / LMM
  if (mtype == "GLMM") {
    names(coef_df)[2:5] <- c("b", "SE", "z", "p")
    coef_df$t  <- NA_real_
    coef_df$df <- NA_real_
  } else {
    names(coef_df)[2:6] <- c("b", "SE", "df", "t", "p")
    coef_df$z  <- NA_real_
  }

  # Wald 95% CI
  ci <- tryCatch(
    confint(m, method = "Wald", parm = "beta_") %>%
      as.data.frame() %>%
      rownames_to_column("term") %>%
      rename(CI_lower = `2.5 %`, CI_upper = `97.5 %`),
    error = function(e) {
      data.frame(term = coef_df$term, CI_lower = NA_real_, CI_upper = NA_real_)
    }
  )

  coef_df %>%
    left_join(ci, by = "term") %>%
    mutate(
      task          = task,
      outcome       = outcome,
      model_type    = mtype,
      random_fx     = result$formula_used,
      singular_flag = result$singular,
      sig           = p < .05
    ) %>%
    select(task, outcome, model_type, term, b, SE, CI_lower, CI_upper,
           z, t, df, p, sig, random_fx, singular_flag)
}

# =============================================================================
# MAIN LOOP
# =============================================================================

all_fe      <- list()
all_re_log  <- list()
sink_file   <- file.path(OUTPUT_DIR, "LCYA_Model_Summaries.txt")
sink(sink_file)
cat("LCYA Revision — Random Slopes Model Summaries\nGenerated:", format(Sys.time()), "\n\n")
sink()

run_and_log <- function(label, result, task, outcome, mtype) {
  sink(sink_file, append = TRUE)
  cat(paste(rep("-", 60), collapse = ""), "\n")
  cat("MODEL:", label, "\nFinal formula:", result$formula_used, "\n\n")
  if (!is.null(result$model)) print(summary(result$model))
  cat("\n")
  sink()

  fe <- extract_fe(result, task, outcome, mtype)
  all_fe[[label]]     <<- fe
  all_re_log[[label]] <<- tibble(
    label         = label,
    task          = task,
    outcome       = outcome,
    final_formula = result$formula_used,
    singular      = result$singular
  )
}

for (task_name in TASKS) {
  cat("\n", strrep("=", 60), "\n")
  cat("TASK:", task_name, "\n")
  cat(strrep("=", 60), "\n")

  cfg <- TASK_CFG[[task_name]]
  raw <- load_raw(task_name)

  # ── Trial-level behavioral data ──────────────────────────────────────────
  beh <- trial_behavioral(raw)
  cat("  Behavioral trials:", nrow(beh), "| Subjects:", n_distinct(beh$sub), "\n")

  # ── Trial-level AUC data ─────────────────────────────────────────────────
  cat("  Computing trial-level AUC (this may take a moment)...\n")
  auc_data <- compute_trial_auc(raw, cfg)
  cat("  AUC trials computed:", nrow(auc_data), "\n")

  # ── 1. GLMM: Accuracy ────────────────────────────────────────────────────
  cat("\n--- GLMM: Accuracy ---\n")
  r_acc <- fit_reduced(
    "iscorr ~ difficulty * effort + (1 + difficulty + effort + difficulty:effort | sub)",
    data = beh, family = binomial(link = "logit"),
    label = paste(task_name, "Accuracy")
  )
  run_and_log(paste(task_name, "Accuracy"), r_acc, task_name, "Accuracy", "GLMM")

  # ── 2. LMM: Reaction Time ────────────────────────────────────────────────
  cat("\n--- LMM: Reaction Time ---\n")
  r_rt <- fit_reduced(
    "log_rt ~ difficulty * effort + (1 + difficulty + effort + difficulty:effort | sub)",
    data = beh, family = NULL,
    label = paste(task_name, "RT")
  )
  run_and_log(paste(task_name, "RT"), r_rt, task_name, "Reaction_Time_log", "LMM")

  # ── 3. LMM: Total AUC ────────────────────────────────────────────────────
  cat("\n--- LMM: Total AUC ---\n")
  auc_total_dat <- auc_data %>% filter(!is.na(Total_AUC))

  # CDT: difficulty unknown during AUC window — effort-only model
  total_formula <- if (task_name == "CDT") {
    "Total_AUC ~ effort + (1 + effort | sub)"
  } else {
    "Total_AUC ~ difficulty * effort + (1 + difficulty + effort + difficulty:effort | sub)"
  }
  r_total <- fit_reduced(total_formula, data = auc_total_dat,
                         label = paste(task_name, "Total_AUC"))
  run_and_log(paste(task_name, "Total_AUC"), r_total,
              task_name, "Total_AUC", "LMM")

  # ── 4. LMM: Cognitive AUC (ADT and VDT only) ─────────────────────────────
  if (task_name != "CDT") {
    cat("\n--- LMM: Cognitive AUC ---\n")
    auc_cog_dat <- auc_data %>% filter(!is.na(Cognitive_AUC))
    r_cog <- fit_reduced(
      "Cognitive_AUC ~ difficulty * effort + (1 + difficulty + effort + difficulty:effort | sub)",
      data = auc_cog_dat,
      label = paste(task_name, "Cognitive_AUC")
    )
    run_and_log(paste(task_name, "Cognitive_AUC"), r_cog,
                task_name, "Cognitive_AUC", "LMM")
  }
}

# =============================================================================
# COMPILE AND SAVE
# =============================================================================

cat("\n", strrep("=", 60), "\n")
cat("COMPILING AND SAVING OUTPUTS\n")
cat(strrep("=", 60), "\n")

# --- Comprehensive fixed-effects table ---
term_labels <- c(
  "(Intercept)"              = "Intercept",
  "difficultyHard"           = "Task Difficulty (Hard vs. Easy)",
  "effortHigh"               = "Physical Effort (High vs. Low)",
  "difficultyHard:effortHigh" = "Task Difficulty × Physical Effort"
)

fe_table <- bind_rows(all_fe) %>%
  mutate(
    term_clean = recode(term, !!!term_labels, .default = term),
    across(c(b, SE, CI_lower, CI_upper, z, t, df, p), ~ round(.x, 4))
  ) %>%
  select(task, outcome, model_type, term_clean, term, b, SE,
         CI_lower, CI_upper, z, t, df, p, sig,
         random_fx, singular_flag)

write_csv(fe_table, file.path(OUTPUT_DIR, "LCYA_FixedEffects_AllModels.csv"))
cat("Saved: LCYA_FixedEffects_AllModels.csv\n")

# --- Random effects structure log ---
re_log <- bind_rows(all_re_log)
write_csv(re_log, file.path(OUTPUT_DIR, "LCYA_RandomEffects_Structure.csv"))
cat("Saved: LCYA_RandomEffects_Structure.csv\n")

# --- Append table to summary text file ---
sink(sink_file, append = TRUE)
cat("\n\n", strrep("=", 60), "\n")
cat("COMPREHENSIVE FIXED-EFFECTS TABLE\n")
cat(strrep("=", 60), "\n\n")
cat("Columns: b = unstandardised coefficient | SE = standard error\n")
cat("CI_lower/upper = Wald 95% CI | p from Wald test | sig = p < .05\n\n")
print(as.data.frame(fe_table), digits = 4)
sink()
cat("Appended table to: LCYA_Model_Summaries.txt\n")

cat("\n=== DONE ===\n")
cat("All outputs saved to:", OUTPUT_DIR, "\n")
