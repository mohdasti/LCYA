ggplot_objects_distributions <- list(
  plot1 = ggplot(ADT_anova_grip_diff_combined, aes(x = stimLev, y = diff, fill = factor(isStrength))) +
    geom_split_violin(alpha = .5, trim = FALSE) +
    geom_boxplot(width = .2, alpha = .8, fatten = NULL, show.legend = FALSE) +
    scale_fill_manual(values = c("#0072B5FF", "#BC3C29FF"), labels = c("0", "1")) +
    stat_summary(fun.data = "mean_se", geom = "pointrange", show.legend = FALSE, 
                 position = position_dodge(.175)) +
    scale_x_discrete(name = "Oddball level (Hz)") +
    scale_y_continuous(name = "diff", limits = c(0, 1)) +
    ggtitle("Distribution of 'Different' responses — ADT ") +
    labs(fill = "Grip Level"),
  
  plot2 = ggplot(ADT_anova_grip_diff_RT_combinedd, aes(x = stimLev, y = RT, fill = factor(isStrength))) +
    geom_split_violin(alpha = .5, trim = FALSE) +
    geom_boxplot(width = .2, alpha = .8, fatten = NULL, show.legend = FALSE) +
    scale_fill_manual(values = c("#0072B5FF", "#BC3C29FF"), labels = c("0", "1")) +
    stat_summary(fun.data = "mean_se", geom = "pointrange", show.legend = FALSE, 
                 position = position_dodge(.175)) +
    scale_x_discrete(name = "Oddball level") +
    scale_y_continuous(name = "RT", limits = c(0, 3)) +
    ggtitle("Distribution of Correct Median Reaction times — ADT ") +
    labs(fill = "Grip Level"),
  
  plot3 = ggplot(VDT_anova_grip_diff_combined, aes(x = stimLev, y = diff, fill = factor(isStrength))) +
    geom_split_violin(alpha = .5, trim = FALSE) +
    geom_boxplot(width = .2, alpha = .8, fatten = NULL, show.legend = FALSE) +
    scale_fill_manual(values = c("#0072B5FF", "#BC3C29FF"), labels = c("0", "1")) +
    stat_summary(fun.data = "mean_se", geom = "pointrange", show.legend = FALSE, 
                 position = position_dodge(.175)) +
    scale_x_discrete(name = "Oddball level") +
    scale_y_continuous(name = "diff", limits = c(0, 1)) +
    ggtitle("Distribution of 'Different' responses — VDT ") +
    labs(fill = "Grip Level"),
  
  plot4 = ggplot(VDT_anova_grip_diff_RT_combinedd, aes(x = stimLev, y = RT, fill = factor(isStrength))) +
    geom_split_violin(alpha = .5, trim = FALSE) +
    geom_boxplot(width = .2, alpha = .8, fatten = NULL, show.legend = FALSE) +
    scale_fill_manual(values = c("#0072B5FF", "#BC3C29FF"), labels = c("0", "1")) +
    stat_summary(fun.data = "mean_se", geom = "pointrange", show.legend = FALSE, 
                 position = position_dodge(.175)) +
    scale_x_discrete(name = "Oddball level") +
    scale_y_continuous(name = "RT", limits = c(0, 3)) +
    ggtitle("Distribution of Correct Median Reaction times — VDT ") +
    labs(fill = "Grip Level"),
  
  plot5 = ggplot(CDT_anova_grip_diff_combined, aes(x = stimLev, y = diff, fill = factor(isStrength))) +
    geom_split_violin(alpha = .5, trim = FALSE) +
    geom_boxplot(width = .2, alpha = .8, fatten = NULL, show.legend = FALSE) +
    scale_fill_manual(values = c("#0072B5FF", "#BC3C29FF"), labels = c("0", "1")) +
    stat_summary(fun.data = "mean_se", geom = "pointrange", show.legend = FALSE, 
                 position = position_dodge(.175)) +
    scale_x_discrete(name = "Oddball level") +
    scale_y_continuous(name = "diff", limits = c(0, 1)) +
    ggtitle("Distribution of 'Different' responses — CDT ") +
    labs(fill = "Grip Level"),
  
  plot6 = ggplot(CDT_anova_grip_diff_RT_combinedd, aes(x = stimLev, y = RT, fill = factor(isStrength))) +
    geom_split_violin(alpha = .5, trim = FALSE) +
    geom_boxplot(width = .2, alpha = .8, fatten = NULL, show.legend = FALSE) +
    scale_fill_manual(values = c("#0072B5FF", "#BC3C29FF"), labels = c("0", "1")) +
    stat_summary(fun.data = "mean_se", geom = "pointrange", show.legend = FALSE, 
                 position = position_dodge(.175)) +
    scale_x_discrete(name = "Oddball level") +
    scale_y_continuous(name = "RT", limits = c(0, 3)) +
    ggtitle("Distribution of Correct Median Reaction times — CDT ") +
    labs(fill = "Grip Level")
  
)
