#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
})

BASE_DIR <- "/Users/mohdasti/Documents/LC–YA"
DATA_DIR <- file.path(BASE_DIR, "PI_Feedback_Outputs")
RESULTS_DIR <- file.path(BASE_DIR, "results")
MODELS_DIR <- file.path(BASE_DIR, "models")
DIAG_DIR <- file.path(BASE_DIR, "diagnostics")

if (!dir.exists(RESULTS_DIR)) dir.create(RESULTS_DIR, recursive = TRUE)
if (!dir.exists(MODELS_DIR)) dir.create(MODELS_DIR, recursive = TRUE)
if (!dir.exists(DIAG_DIR)) dir.create(DIAG_DIR, recursive = TRUE)

message("=== Bivariate brms Individual Differences Analysis ===")
message("Start: ", Sys.time())

# Check for required packages
need_pkg <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(sprintf("Package '%s' is required. Please install it: install.packages('%s')", pkg, pkg))
  }
}

need_pkg("brms")
need_pkg("posterior")

suppressPackageStartupMessages({
  library(brms)
  library(posterior)
})

# Try cmdstanr backend if available
backend <- NULL
if (requireNamespace("cmdstanr", quietly = TRUE)) {
  backend <- "cmdstanr"
} else {
  backend <- "rstan"  # fallback
}

# Load datasets
dual_auc_path <- file.path(DATA_DIR, "Combined_Dual_AUC_Data.csv")
behavior_path <- file.path(BASE_DIR, "Complete_Manuscript_Results", "complete_analysis_data.csv")

stopifnot(file.exists(dual_auc_path))
stopifnot(file.exists(behavior_path))

dual_auc_data <- readr::read_csv(dual_auc_path, show_col_types = FALSE)
behavioral_data <- readr::read_csv(behavior_path, show_col_types = FALSE)

# Merge per-condition AUC and behavior
processed_data <- dual_auc_data %>%
  mutate(
    sub = as.numeric(sub),
    difficulty = stringr::str_extract(condition, "^[^/]+") %>% stringr::str_trim(),
    effort = stringr::str_extract(condition, "[^/]+$") %>% stringr::str_trim(),
    task = factor(task, levels = c("CDT", "ADT", "VDT")),
    mean_total_auc = mean_physical_auc,
    mean_cognitive_auc = mean_cognitive_auc
  )

behavioral_summary <- behavioral_data %>%
  filter(!is.na(accuracy)) %>%
  group_by(sub, task, difficulty, effort) %>%
  summarise(mean_accuracy = mean(accuracy, na.rm = TRUE), .groups = 'drop') %>%
  mutate(
    sub = as.numeric(stringr::str_remove(sub, "S")),
    difficulty = factor(difficulty, levels = c("Easy", "Hard")),
    effort = factor(effort, levels = c("Low", "High")),
    task = factor(task, levels = c("CDT", "ADT", "VDT"))
  )

merged_data <- processed_data %>%
  left_join(behavioral_summary, by = c("sub", "task", "difficulty", "effort"))

message("Data prepared. N rows: ", nrow(merged_data))

# Prepare condition-level bivariate wide data (two responses: auc_value, acc_value)
prepare_bivariate_wide <- function(data, task_name, measure_var, effort_type = c("physical", "cognitive")) {
  effort_type <- match.arg(effort_type)
  dat <- data %>% filter(task == task_name, !is.na(.data[[measure_var]]), !is.na(mean_accuracy))
  if (effort_type == "physical") {
    dat <- dat %>%
      mutate(
        effort_contrast = ifelse(effort == "High", 0.5, -0.5),
        difficulty_contrast = ifelse(difficulty == "Hard", 0.5, -0.5)
      )
  } else {
    dat <- dat %>%
      mutate(
        difficulty_contrast = ifelse(difficulty == "Hard", 0.5, -0.5),
        effort_contrast = ifelse(effort == "High", 0.5, -0.5)
      )
  }
  dat %>%
    transmute(
      sub = sub,
      task = task,
      effort_contrast = effort_contrast,
      difficulty_contrast = difficulty_contrast,
      auc_value = .data[[measure_var]],
      acc_value = mean_accuracy
    )
}

# Fit multi-response brms model with random slope correlations across responses
fit_bivariate_effort_model <- function(wide_data, save_prefix) {
  bf_auc <- bf(
    auc_value ~ 1 + effort_contrast + difficulty_contrast + effort_contrast:difficulty_contrast +
      (1 + effort_contrast | p | sub)
  )
  bf_acc <- bf(
    acc_value ~ 1 + effort_contrast + difficulty_contrast + effort_contrast:difficulty_contrast +
      (1 + effort_contrast | p | sub)
  )
  priors <- c(
    prior(normal(0, 5), class = b),
    prior(lkj(2), class = cor)
  )
  fit <- brm(
    bf_auc + bf_acc + set_rescor(FALSE),
    data = wide_data,
    family = gaussian(),
    prior = priors,
    chains = 2, iter = 2000, warmup = 1000, cores = 2,
    control = list(adapt_delta = 0.95, max_treedepth = 12),
    backend = backend,
    file = file.path(MODELS_DIR, save_prefix)
  )
  fit
}

# Extract correlation between physiological and behavioral random slopes for effort_contrast
extract_slope_correlation <- function(fit) {
  draws <- posterior::as_draws_df(fit)
  # Typical pattern in multivariate models: cor_sub__auc_value_effort_contrast__acc_value_effort_contrast
  cor_cols <- names(draws)[grepl("^cor_sub__.*auc_value.*effort_contrast__.*acc_value.*effort_contrast$", names(draws))]
  if (length(cor_cols) == 0) {
    # Fallback: any correlation between two effort_contrast slopes
    cor_cols <- names(draws)[grepl("^cor_sub__.*effort_contrast__.*effort_contrast$", names(draws))]
  }
  if (length(cor_cols) == 0) return(NULL)
  cor_vec <- draws[[cor_cols[1]]]
  tibble(
    param = cor_cols[1],
    mean = mean(cor_vec),
    median = median(cor_vec),
    sd = sd(cor_vec),
    lower_95 = quantile(cor_vec, 0.025),
    upper_95 = quantile(cor_vec, 0.975),
    prob_positive = mean(cor_vec > 0),
    prob_negative = mean(cor_vec < 0)
  )
}

# Exemplar run: ADT, Total AUC × physical effort
try({
  task_name <- "ADT"
  measure_var <- "mean_total_auc"
  effort_type <- "physical"
  wide <- prepare_bivariate_wide(merged_data, task_name, measure_var, effort_type)
  message("Prepared exemplar wide data: ", task_name, " ", measure_var, ", N = ", nrow(wide))
  fit <- fit_bivariate_effort_model(wide, save_prefix = paste0("bivar_wide_", task_name, "_", measure_var, "_", effort_type))
  summ <- extract_slope_correlation(fit)
  if (!is.null(summ)) {
    summ$model <- paste(task_name, measure_var, effort_type, sep = "_")
    readr::write_csv(summ, file.path(RESULTS_DIR, paste0("summary_", task_name, "_", measure_var, "_", effort_type, "_slope_correlation.csv")))
    print(summ)
  } else {
    message("Could not locate slope correlation parameter in posterior draws.")
  }
}, silent = FALSE)

# ---- Batch primary analyses and combined summary ----
try({
  runs <- tribble(
    ~task, ~measure_var,        ~effort_type,   ~prefix,
    "CDT",  "mean_total_auc",   "physical",     "bivar_wide_CDT_TotalAUC_physical",
    "ADT",  "mean_total_auc",   "physical",     "bivar_wide_ADT_TotalAUC_physical",
    "VDT",  "mean_total_auc",   "physical",     "bivar_wide_VDT_TotalAUC_physical",
    # Cognitive AUC × cognitive effort (ADT, VDT only)
    "ADT",  "mean_cognitive_auc","cognitive",    "bivar_wide_ADT_CogAUC_cognitive",
    "VDT",  "mean_cognitive_auc","cognitive",    "bivar_wide_VDT_CogAUC_cognitive"
  )
  all_summaries <- list()
  for (i in seq_len(nrow(runs))) {
    task_i <- runs$task[i]
    meas_i <- runs$measure_var[i]
    eff_i  <- runs$effort_type[i]
    pref_i <- runs$prefix[i]
    wide_i <- prepare_bivariate_wide(merged_data, task_i, meas_i, eff_i)
    message(sprintf("Running %s | %s × %s | N=%d", task_i, meas_i, eff_i, nrow(wide_i)))
    fit_i <- fit_bivariate_effort_model(wide_i, save_prefix = pref_i)
    summ_i <- extract_slope_correlation(fit_i)
    if (!is.null(summ_i)) {
      summ_i$model <- paste(task_i, meas_i, eff_i, sep = "_")
      readr::write_csv(summ_i, file.path(RESULTS_DIR, paste0("summary_", task_i, "_", meas_i, "_", eff_i, "_slope_correlation.csv")))
      all_summaries[[length(all_summaries)+1]] <- summ_i
    } else {
      message("No slope correlation parameter found for ", task_i, " ", meas_i, " ", eff_i)
    }
  }
  if (length(all_summaries) > 0) {
    combined <- dplyr::bind_rows(all_summaries)
    readr::write_csv(combined, file.path(RESULTS_DIR, "primary_individual_differences_slope_correlations.csv"))
    print(combined)
  }
}, silent = FALSE)

# ---- Pooled (hierarchical across tasks) analyses ----
prepare_pooled_wide <- function(data, tasks, measure_var, effort_type = c("physical", "cognitive")) {
  effort_type <- match.arg(effort_type)
  dat <- data %>% filter(task %in% tasks, !is.na(.data[[measure_var]]), !is.na(mean_accuracy))
  if (effort_type == "physical") {
    dat <- dat %>%
      mutate(
        effort_contrast = ifelse(effort == "High", 0.5, -0.5),
        difficulty_contrast = ifelse(difficulty == "Hard", 0.5, -0.5)
      )
  } else {
    dat <- dat %>%
      mutate(
        difficulty_contrast = ifelse(difficulty == "Hard", 0.5, -0.5),
        effort_contrast = ifelse(effort == "High", 0.5, -0.5)
      )
  }
  dat %>%
    transmute(
      sub = sub,
      task = task,
      effort_contrast = effort_contrast,
      difficulty_contrast = difficulty_contrast,
      auc_value = .data[[measure_var]],
      acc_value = mean_accuracy
    )
}

fit_pooled_bivariate <- function(wide_data, save_prefix) {
  bf_auc <- bf(
    auc_value ~ 1 + effort_contrast + difficulty_contrast + effort_contrast:difficulty_contrast +
      (1 + effort_contrast | p | sub) + (1 + effort_contrast | task)
  )
  bf_acc <- bf(
    acc_value ~ 1 + effort_contrast + difficulty_contrast + effort_contrast:difficulty_contrast +
      (1 + effort_contrast | p | sub) + (1 + effort_contrast | task)
  )
  priors <- c(
    prior(normal(0, 5), class = b),
    prior(lkj(2), class = cor)
  )
  fit <- brm(
    bf_auc + bf_acc + set_rescor(FALSE),
    data = wide_data,
    family = gaussian(),
    prior = priors,
    chains = 4, iter = 5000, warmup = 2500, cores = 4,
    control = list(adapt_delta = 0.99, max_treedepth = 13),
    backend = backend,
    file = file.path(MODELS_DIR, save_prefix)
  )
  fit
}

pooled_diag_text <- function(fit) {
  rhat_vals <- tryCatch(rhat(fit), error = function(e) NA)
  ess_vals <- tryCatch(ess_bulk(fit), error = function(e) NA)
  nuts <- tryCatch(nuts_params(fit), error = function(e) NULL)
  ndiv <- if (!is.null(nuts) && !is.null(nuts$divergent__)) sum(nuts$divergent__) else NA
  paste0(
    "Rhat_max=", ifelse(all(is.na(rhat_vals)), "NA", sprintf("%.3f", max(rhat_vals, na.rm = TRUE))), ", ",
    "ESS_min=", ifelse(all(is.na(ess_vals)), "NA", sprintf("%.0f", min(ess_vals, na.rm = TRUE))), ", ",
    "Divergences=", ifelse(is.na(ndiv), "NA", ndiv)
  )
}

# Run pooled models (strict HMC settings)
try({
  # Total AUC × physical across CDT/ADT/VDT
  pooled_total <- prepare_pooled_wide(merged_data, c("CDT", "ADT", "VDT"), "mean_total_auc", "physical")
  message("Running pooled Total AUC × physical across tasks (strict) | N=", nrow(pooled_total))
  fit_pooled_total <- fit_pooled_bivariate(pooled_total, save_prefix = "bivar_wide_POOLS_TotalAUC_physical_strict")
  summ_pooled_total <- extract_slope_correlation(fit_pooled_total)
  diag_total <- pooled_diag_text(fit_pooled_total)
  if (!is.null(summ_pooled_total)) {
    summ_pooled_total$model <- "POOLED_TotalAUC_Physical_strict"
    readr::write_csv(summ_pooled_total, file.path(RESULTS_DIR, "summary_POOLED_TotalAUC_Physical_slope_correlation_strict.csv"))
  }
  writeLines(diag_total, file.path(RESULTS_DIR, "diagnostics_POOLED_TotalAUC_Physical.txt"))
  # Cognitive AUC × cognitive across ADT/VDT
  pooled_cog <- prepare_pooled_wide(merged_data, c("ADT", "VDT"), "mean_cognitive_auc", "cognitive")
  message("Running pooled Cognitive AUC × cognitive across tasks (strict) | N=", nrow(pooled_cog))
  fit_pooled_cog <- fit_pooled_bivariate(pooled_cog, save_prefix = "bivar_wide_POOLS_CogAUC_cognitive_strict")
  summ_pooled_cog <- extract_slope_correlation(fit_pooled_cog)
  diag_cog <- pooled_diag_text(fit_pooled_cog)
  if (!is.null(summ_pooled_cog)) {
    summ_pooled_cog$model <- "POOLED_CogAUC_Cognitive_strict"
    readr::write_csv(summ_pooled_cog, file.path(RESULTS_DIR, "summary_POOLED_CogAUC_Cognitive_slope_correlation_strict.csv"))
  }
  writeLines(diag_cog, file.path(RESULTS_DIR, "diagnostics_POOLED_CogAUC_Cognitive.txt"))
}, silent = FALSE)

# ---- rmcorr sensitivity: run existing script and capture log ----
try({
  rmcorr_script <- file.path(BASE_DIR, "Corrected_Individual_Differences_rmcorr.R")
  if (file.exists(rmcorr_script)) {
    system2("Rscript", args = c(shQuote(rmcorr_script)), stdout = file.path(RESULTS_DIR, "rmcorr_log.txt"), stderr = file.path(RESULTS_DIR, "rmcorr_log.txt"))
  }
}, silent = TRUE)

# ---- Write consolidated Markdown report ----
try({
  primary_csv <- file.path(RESULTS_DIR, "primary_individual_differences_slope_correlations.csv")
  pooled_total_csv <- file.path(RESULTS_DIR, "summary_POOLED_TotalAUC_Physical_slope_correlation_strict.csv")
  pooled_cog_csv <- file.path(RESULTS_DIR, "summary_POOLED_CogAUC_Cognitive_slope_correlation_strict.csv")
  diag_total_path <- file.path(RESULTS_DIR, "diagnostics_POOLED_TotalAUC_Physical.txt")
  diag_cog_path <- file.path(RESULTS_DIR, "diagnostics_POOLED_CogAUC_Cognitive.txt")
  rmcorr_log_path <- file.path(RESULTS_DIR, "rmcorr_log.txt")
  primary_tbl <- if (file.exists(primary_csv)) readr::read_csv(primary_csv, show_col_types = FALSE) else tibble()
  pooled_total_tbl <- if (file.exists(pooled_total_csv)) readr::read_csv(pooled_total_csv, show_col_types = FALSE) else tibble()
  pooled_cog_tbl <- if (file.exists(pooled_cog_csv)) readr::read_csv(pooled_cog_csv, show_col_types = FALSE) else tibble()
  rmcorr_log <- if (file.exists(rmcorr_log_path)) paste(readLines(rmcorr_log_path), collapse = "\n") else "(rmcorr log not available)"
  diag_total <- if (file.exists(diag_total_path)) paste(readLines(diag_total_path), collapse = "\n") else "(diagnostics not available)"
  diag_cog <- if (file.exists(diag_cog_path)) paste(readLines(diag_cog_path), collapse = "\n") else "(diagnostics not available)"

  fmt <- function(x) ifelse(is.na(x), "NA", sprintf("%.3f", x))

  md_path <- file.path(RESULTS_DIR, "Individual_Differences_Brms_Report.md")
  lines <- c(
    "# Individual Differences: Bivariate brms Analysis and Sensitivity",
    "",
    "## Data & Measures",
    "- Source AUC: `PI_Feedback_Outputs/Combined_Dual_AUC_Data.csv`",
    "- Source behavior: `Complete_Manuscript_Results/complete_analysis_data.csv`",
    "- Measures: `mean_total_auc` (Total AUC), `mean_cognitive_auc` (Cognitive AUC), behavior `mean_accuracy`.",
    "",
    "## Model Specifications (brms)",
    "- Per-task primary models (two-response multivariate):",
    "  - auc_value ~ 1 + effort_contrast + difficulty_contrast + effort_contrast:difficulty_contrast + (1 + effort_contrast | p | sub)",
    "  - acc_value ~ 1 + effort_contrast + difficulty_contrast + effort_contrast:difficulty_contrast + (1 + effort_contrast | p | sub)",
    "  - Target estimand: correlation between subject-specific effort slopes across outcomes (random-slope correlation).",
    "- Pooled models (hierarchical across tasks): add (1 + effort_contrast | task) to both responses.",
    "- Priors: normal(0,5) for b; LKJ(2) for cor; Gaussian family; rescor = FALSE.",
    "",
    "## Primary Results (Per Task)",
    "Columns: model, mean, median, sd, 95% CrI, Pr(>0), Pr(<0)",
    "",
    if (nrow(primary_tbl) > 0) paste0("| ", paste(c("model","mean","median","sd","lower_95","upper_95","prob_positive","prob_negative"), collapse = " | "), " |\n|", paste(rep("---",8), collapse = "|"), "|") else "(no primary results)",
    if (nrow(primary_tbl) > 0) paste(apply(primary_tbl %>% mutate(across(c(mean, median, sd, lower_95, upper_95, prob_positive, prob_negative), fmt)) %>% select(model, mean, median, sd, lower_95, upper_95, prob_positive, prob_negative), 1, function(r) paste0("| ", paste(r, collapse = " | "), " |")), collapse = "\n") else "",
    "",
    "## Pooled Results (Across Tasks, Strict HMC)",
    "",
    if (nrow(pooled_total_tbl) > 0) paste0("- POOLED_TotalAUC_Physical: mean=", fmt(pooled_total_tbl$mean[1]), ", median=", fmt(pooled_total_tbl$median[1]), ", 95% CrI [", fmt(pooled_total_tbl$lower_95[1]), ", ", fmt(pooled_total_tbl$upper_95[1]), "]", ", Pr(>0)=", fmt(pooled_total_tbl$prob_positive[1])) else "- POOLED_TotalAUC_Physical: (not available)",
    paste0("  Diagnostics: ", diag_total),
    if (nrow(pooled_cog_tbl) > 0) paste0("- POOLED_CogAUC_Cognitive: mean=", fmt(pooled_cog_tbl$mean[1]), ", median=", fmt(pooled_cog_tbl$median[1]), ", 95% CrI [", fmt(pooled_cog_tbl$lower_95[1]), ", ", fmt(pooled_cog_tbl$upper_95[1]), "]", ", Pr(>0)=", fmt(pooled_cog_tbl$prob_positive[1])) else "- POOLED_CogAUC_Cognitive: (not available)",
    paste0("  Diagnostics: ", diag_cog),
    "",
    "## Sensitivity: rmcorr (difference scores)",
    "```",
    rmcorr_log,
    "```",
    "",
    "## File Outputs",
    "- Primary CSV: `results/primary_individual_differences_slope_correlations.csv`",
    "- Pooled CSVs: `results/summary_POOLED_TotalAUC_Physical_slope_correlation_strict.csv`, `results/summary_POOLED_CogAUC_Cognitive_slope_correlation_strict.csv`",
    "- Diagnostics: `results/diagnostics_POOLED_TotalAUC_Physical.txt`, `results/diagnostics_POOLED_CogAUC_Cognitive.txt`",
    "- rmcorr log: `results/rmcorr_log.txt`",
    "- Model objects: `models/` (one .rds per fit)"
  )
  writeLines(lines, md_path)
  message("Report written: ", md_path)
}, silent = FALSE)

message("Done: ", Sys.time())
