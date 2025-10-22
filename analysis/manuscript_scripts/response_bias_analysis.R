# Response Bias Analysis using GLMM
# Modeling how cognitive load and physical effort affect response bias
# For ADT, VDT, and CDT tasks

library(dplyr)
library(lme4)
library(ggplot2)
library(purrr)
library(readr)

# Function to load and prepare task data
load_task_data <- function(task_name) {
  cat("Loading", task_name, "data...\n")
  
  # Load the aggregated trial-level data with correct file names
  if (task_name == "ADT") {
    data_path <- "lcya_behdata_trial_avdt.csv"
    data <- read_csv(data_path)
    # Filter for auditory task
    data <- data %>% filter(task == "aud")
  } else if (task_name == "VDT") {
    data_path <- "lcya_behdata_trial_avdt.csv"
    data <- read_csv(data_path)
    # Filter for visual task
    data <- data %>% filter(task == "vis")
  } else if (task_name == "CDT") {
    data_path <- "lcya_behdata_trial_cdt.csv"
    data <- read_csv(data_path)
  } else {
    stop("Unknown task name")
  }
  
  cat("Loaded", nrow(data), "trials for", task_name, "\n")
  
  # Prepare data for analysis
  data <- data %>%
    mutate(
      sub = as.factor(sub),
      stimLev = as.factor(stimLev),
      isOddball = as.factor(isOddball),
      resp1_diff = as.numeric(resp1_diff)
    ) %>%
    # Remove any missing values for key variables
    filter(!is.na(resp1_diff), 
           !is.na(isOddball), 
           !is.na(stimLev), 
           !is.na(auc_rel_mvc))
  
  cat("After filtering,", nrow(data), "trials remain for", task_name, "\n")
  cat("Response distribution:\n")
  print(table(data$resp1_diff, useNA = "ifany"))
  cat("Oddball distribution:\n")
  print(table(data$isOddball, useNA = "ifany"))
  cat("Stimulus level distribution:\n")
  print(table(data$stimLev, useNA = "ifany"))
  
  return(data)
}

# Function to fit GLMM and analyze response bias
analyze_response_bias <- function(data, task_name) {
  cat("\n", paste0("=", "=", "=", " ", task_name, " RESPONSE BIAS ANALYSIS ", "=", "=", "="), "\n")
  
  # Fit the GLMM model
  cat("Fitting GLMM model...\n")
  
  glmm_bias <- glmer(resp1_diff ~ isOddball * stimLev * auc_rel_mvc + (1 | sub), 
                     data = data, 
                     family = binomial,
                     control = glmerControl(optimizer = "bobyqa"))
  
  # Print model summary
  cat("\n---", task_name, "GLMM Model Summary ---\n")
  print(summary(glmm_bias))
  
  # Extract and interpret key effects
  cat("\n---", task_name, "Key Effects Interpretation ---\n")
  
  # Get fixed effects
  fe <- fixef(glmm_bias)
  se <- sqrt(diag(vcov(glmm_bias)))
  
  # Main effect of physical effort (auc_rel_mvc)
  if ("auc_rel_mvc" %in% names(fe)) {
    effort_effect <- fe["auc_rel_mvc"]
    effort_se <- se["auc_rel_mvc"]
    effort_z <- effort_effect / effort_se
    effort_p <- 2 * (1 - pnorm(abs(effort_z)))
    
    cat("Main Effect of Physical Effort (auc_rel_mvc):\n")
    cat("  Estimate:", round(effort_effect, 4), "\n")
    cat("  SE:", round(effort_se, 4), "\n")
    cat("  Z-value:", round(effort_z, 4), "\n")
    cat("  P-value:", round(effort_p, 4), "\n")
    
    if (effort_effect > 0) {
      cat("  Interpretation: Higher physical effort makes participants MORE LIBERAL\n")
      cat("  (more likely to respond 'Different' on non-oddball trials)\n")
    } else {
      cat("  Interpretation: Higher physical effort makes participants MORE CONSERVATIVE\n")
      cat("  (less likely to respond 'Different' on non-oddball trials)\n")
    }
  }
  
  # Interaction of isOddball:auc_rel_mvc
  if ("isOddball1:auc_rel_mvc" %in% names(fe)) {
    oddball_effort_int <- fe["isOddball1:auc_rel_mvc"]
    oddball_effort_se <- se["isOddball1:auc_rel_mvc"]
    oddball_effort_z <- oddball_effort_int / oddball_effort_se
    oddball_effort_p <- 2 * (1 - pnorm(abs(oddball_effort_z)))
    
    cat("\nInteraction: isOddball × Physical Effort:\n")
    cat("  Estimate:", round(oddball_effort_int, 4), "\n")
    cat("  SE:", round(oddball_effort_se, 4), "\n")
    cat("  Z-value:", round(oddball_effort_z, 4), "\n")
    cat("  P-value:", round(oddball_effort_p, 4), "\n")
    
    if (oddball_effort_p < 0.05) {
      cat("  Interpretation: Physical effort has DIFFERENT effects on oddball vs non-oddball trials\n")
    } else {
      cat("  Interpretation: Physical effort has SIMILAR effects on oddball and non-oddball trials\n")
    }
  }
  
  # Model fit statistics
  cat("\n---", task_name, "Model Fit Statistics ---\n")
  cat("AIC:", round(AIC(glmm_bias), 2), "\n")
  cat("BIC:", round(BIC(glmm_bias), 2), "\n")
  cat("Log-likelihood:", round(logLik(glmm_bias), 2), "\n")
  
  # Random effects summary
  cat("\nRandom Effects (Subject-level variance):\n")
  re <- VarCorr(glmm_bias)
  print(re)
  
  return(glmm_bias)
}

# Function to create descriptive plots
create_bias_plots <- function(data, task_name) {
  cat("\nCreating descriptive plots for", task_name, "...\n")
  
  # Plot 1: Response bias by physical effort and oddball presence
  p1 <- ggplot(data, aes(x = auc_rel_mvc, y = resp1_diff, color = isOddball)) +
    geom_jitter(alpha = 0.3, width = 0.02, height = 0.02) +
    geom_smooth(method = "glm", method.args = list(family = "binomial")) +
    labs(title = paste(task_name, "- Response Bias by Physical Effort"),
         x = "Physical Effort (auc_rel_mvc)",
         y = "Response (1=Different, 0=Same)",
         color = "Oddball Present") +
    theme_minimal()
  
  # Plot 2: Response bias by stimulus level and physical effort
  p2 <- ggplot(data, aes(x = auc_rel_mvc, y = resp1_diff, color = stimLev)) +
    geom_jitter(alpha = 0.3, width = 0.02, height = 0.02) +
    geom_smooth(method = "glm", method.args = list(family = "binomial")) +
    labs(title = paste(task_name, "- Response Bias by Stimulus Level"),
         x = "Physical Effort (auc_rel_mvc)",
         y = "Response (1=Different, 0=Same)",
         color = "Stimulus Level") +
    theme_minimal()
  
  # Save plots
  ggsave(paste0(task_name, "_response_bias_effort.png"), p1, width = 10, height = 6, dpi = 300)
  ggsave(paste0(task_name, "_response_bias_stimlev.png"), p2, width = 10, height = 6, dpi = 300)
  
  cat("Plots saved for", task_name, "\n")
  
  return(list(p1 = p1, p2 = p2))
}

# Main analysis execution
cat("=== RESPONSE BIAS ANALYSIS USING GLMM ===\n")
cat("Analyzing ADT, VDT, and CDT tasks\n\n")

# Load data for each task
tasks <- c("ADT", "VDT", "CDT")
task_data <- list()
task_models <- list()
task_plots <- list()

for (task in tasks) {
  # Load data
  task_data[[task]] <- load_task_data(task)
  
  # Fit GLMM model
  task_models[[task]] <- analyze_response_bias(task_data[[task]], task)
  
  # Create descriptive plots
  task_plots[[task]] <- create_bias_plots(task_data[[task]], task)
}

# Summary comparison across tasks
cat("\n", paste0("=", "=", "=", " CROSS-TASK COMPARISON ", "=", "=", "="), "\n")

# Extract key effects for comparison
comparison_data <- data.frame(
  Task = tasks,
  N_Trials = sapply(task_data, nrow),
  N_Subjects = sapply(task_data, function(x) n_distinct(x$sub)),
  Effort_Effect = sapply(task_models, function(m) {
    fe <- fixef(m)
    if ("auc_rel_mvc" %in% names(fe)) return(fe["auc_rel_mvc"]) else return(NA)
  }),
  Effort_P = sapply(task_models, function(m) {
    fe <- fixef(m)
    se <- sqrt(diag(vcov(m)))
    if ("auc_rel_mvc" %in% names(fe)) {
      z <- fe["auc_rel_mvc"] / se["auc_rel_mvc"]
      return(2 * (1 - pnorm(abs(z))))
    } else return(NA)
  }),
  AIC = sapply(task_models, AIC)
)

cat("Cross-task comparison of key effects:\n")
print(comparison_data)

# Save comparison table
write.csv(comparison_data, "response_bias_comparison.csv", row.names = FALSE)
cat("\nComparison table saved as 'response_bias_comparison.csv'\n")

cat("\n=== ANALYSIS COMPLETE ===\n")
cat("Key findings:\n")
cat("1. Main effect of physical effort (auc_rel_mvc) indicates response bias shifts\n")
cat("2. Interaction with isOddball shows if effort affects oddball vs non-oddball trials differently\n")
cat("3. Interaction with stimLev shows if effort effects vary by cognitive difficulty\n")
cat("4. Positive estimates = more liberal (more 'Different' responses)\n")
cat("5. Negative estimates = more conservative (fewer 'Different' responses)\n") 