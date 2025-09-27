library(gridExtra)

# Define the grid of plots
grid <- grid.arrange(
  # Row 1: Accuracy for each task
  ggplot(combined_ADT, aes(x = stimLev, y = prop, group = condition, color = condition)) +
    geom_point(size = 2) +
    geom_line(size = 1.2) +
    geom_linerange(mapping = aes(ymin = prop - ifelse(condition == "Different", diff_se, not_diff_se), 
                                 ymax = prop + ifelse(condition == "Different", diff_se, not_diff_se))) +
    ylim(0, 1) +
    ggtitle("Proportion of Responding 'Different' and 'Same' - ADT'") +
    xlab("Oddball Level (Hz)") +
    ylab("Proportion") +
    scale_color_manual(values = c("#BC3C29FF", "#0072B5FF")) +
    guides(color = guide_legend(title = "condition")),
  
  ggplot(combined_VDT, aes(x = stimLev, y = prop, group = condition, color = condition)) +
    geom_point(size = 2) +
    geom_line(size = 1.2) +
    geom_linerange(mapping = aes(ymin = prop - ifelse(condition == "Different", diff_se, not_diff_se), 
                                 ymax = prop + ifelse(condition == "Different", diff_se, not_diff_se))) +
    ylim(0, 1) +
    ggtitle("Proportion of Responding 'Different' and 'Same' - VDT'") +
    xlab("Contrast Level") +
    ylab("Proportion") +
    scale_color_manual(values = c("#BC3C29FF", "#0072B5FF")) +
    guides(color = guide_legend(title = "condition")),
  
  ggplot(combined_CDT, aes(x = stimLev, y = prop, group = condition, color = condition)) +
    geom_point(size = 2) +
    geom_line(size = 1.2) +
    geom_linerange(mapping = aes(ymin = prop - ifelse(condition == "Different", diff_se, not_diff_se), 
                                 ymax = prop + ifelse(condition == "Different", diff_se, not_diff_se))) +
    ylim(0, 1) +
    ggtitle("Proportion of Responding 'Different' and 'Same' - CDT'") +
    xlab("Degree") +
    ylab("Proportion") +
    scale_color_manual(values = c("#BC3C29FF", "#0072B5FF")) +
    guides(color = guide_legend(title = "condition")),
  
  ggplot(combined_MST, aes(x = stimlev_mst, y = prop, group = condition, color = condition)) +
    geom_point(size = 2) +
    geom_line(size = 1.2) +
    geom_linerange(mapping = aes(ymin = prop - ifelse(condition == "Different", diff_se, not_diff_se), 
                                 ymax = prop + ifelse(condition == "Different", diff_se, not_diff_se))) +
    ylim(0, 1) +
    ggtitle("Proportion of Responding 'Different' and 'Same' - MST'") +
    xlab("Similarity Level") +
    ylab("Proportion") +
    scale_color_manual(values = c("#BC3C29FF", "#0072B5FF")) +
    guides(color = guide_legend(title = "condition")),
  
  # Row 2: Reaction time for each task
  ggplot(combined_RT_ADT, aes(x = stimLev, group = condition, color = condition, linetype= condition)) +
    geom_point(aes(y = ifelse(condition == "Different", RT_diff, RT_same)), size = 2) +
    geom_line(aes(y = ifelse(condition == "Different", RT_diff, RT_same)), size = 1.2) +
    ylim(min(c(combined_RT_ADT$RT_diff, combined_RT_ADT$RT_same)), max(c(combined_RT_ADT$RT_diff, combined_RT_ADT$RT_same))) +
    ggtitle("Mean of Median Reaction Time for Same and Different Responses - ADT") +
    geom_linerange(mapping = aes(ymin = RT_diff - RT_diff_se, ymax = RT_diff + RT_diff_se, linetype = condition), data = filter(combined_RT_ADT, condition == "Different")) +
    geom_linerange(mapping = aes(ymin = RT_same - RT_same_se, ymax = RT_same + RT_same_se, linetype = condition), data = filter(combined_RT_ADT, condition == "Same")) +
    labs(caption = "Error bars represent standard error of the mean (SEM)") +
    xlab("Oddball Level (Hz)") +
    ylab("Reaction Time (S)") +
    scale_color_manual(values = c( "#BC3C29FF", "#0072B5FF")) +
    scale_linetype_manual(values = c("Different" = "solid", "Same" = "solid")),
  
  ggplot(combined_RT_VDT, aes(x = stimLev, group = condition, color = condition, linetype= condition)) +
    geom_point(aes(y = ifelse(condition == "Different", RT_diff, RT_same)), size = 2) +
    geom_line(aes(y = ifelse(condition == "Different", RT_diff, RT_same)), size = 1.2) +
    ylim(min(c(combined_RT_VDT$RT_diff, combined_RT_VDT$RT_same)), max(c(combined_RT_VDT$RT_diff, combined_RT_VDT$RT_same))) +
    ggtitle("Mean of Median Reaction Time for Same and Different Responses - VDT") +
    geom_linerange(mapping = aes(ymin = RT_diff - RT_diff_se, ymax = RT_diff + RT_diff_se, linetype = condition), data = filter(combined_RT_VDT, condition == "Different")) +
    geom_linerange(mapping = aes(ymin = RT_same - RT_same_se, ymax = RT_same + RT_same_se, linetype = condition), data = filter(combined_RT_VDT, condition == "Same")) +
    labs(caption = "Error bars represent standard error of the mean (SEM)") +
    xlab("Contrast Level") +
    ylab("Reaction Time (S)") +
    scale_color_manual(values = c( "#BC3C29FF", "#0072B5FF")) +
    scale_linetype_manual(values = c("Different" = "solid", "Same" = "solid")),
  
  ggplot(combined_RT_CDT, aes(x = stimLev, group = condition, color = condition, linetype= condition)) +
    geom_point(aes(y = ifelse(condition == "Different", RT_diff, RT_same)), size = 2) +
    geom_line(aes(y = ifelse(condition == "Different", RT_diff, RT_same)), size = 1.2) +
    ylim(min(c(combined_RT_CDT$RT_diff, combined_RT_CDT$RT_same)), max(c(combined_RT_CDT$RT_diff, combined_RT_ADT$RT_same))) +
    ggtitle("Mean of Median Reaction Time for Same and Different Responses - CDT") +
    geom_linerange(mapping = aes(ymin = RT_diff - RT_diff_se, ymax = RT_diff + RT_diff_se, linetype = condition), data = filter(combined_RT_CDT, condition == "Different")) +
    geom_linerange(mapping = aes(ymin = RT_same - RT_same_se, ymax = RT_same + RT_same_se, linetype = condition), data = filter(combined_RT_CDT, condition == "Same")) +
    labs(caption = "Error bars represent standard error of the mean (SEM)") +
    xlab("Degree") +
    ylab("Reaction Time (S)") +
    scale_color_manual(values = c( "#BC3C29FF", "#0072B5FF")) +
    scale_linetype_manual(values = c("Different" = "solid", "Same" = "solid")),
  
  ggplot(combined_RT_MST, aes(x = stimlev_mst, group = condition, color = condition, linetype= condition)) +
    geom_point(aes(y = ifelse(condition == "Different", RT_diff, RT_same)), size = 2) +
    geom_line(aes(y = ifelse(condition == "Different", RT_diff, RT_same)), size = 1.2) +
    ylim(min(c(combined_RT_MST$RT_diff, combined_RT_MST$RT_same)), max(c(combined_RT_MST$RT_diff, combined_RT_MST$RT_same))) +
    ggtitle("Mean of Median Reaction Time for Same and Different Responses - ADT") +
    geom_linerange(mapping = aes(ymin = RT_diff - RT_diff_se, ymax = RT_diff + RT_diff_se, linetype = condition), data = filter(combined_RT_MST, condition == "Different")) +
    geom_linerange(mapping = aes(ymin = RT_same - RT_same_se, ymax = RT_same + RT_same_se, linetype = condition), data = filter(combined_RT_MST, condition == "Same")) +
    labs(caption = "Error bars represent standard error of the mean (SEM)") +
    xlab("Similarity Level") +
    ylab("Reaction Time (S)") +
    scale_color_manual(values = c( "#BC3C29FF", "#0072B5FF")) +
    scale_linetype_manual(values = c("Different" = "solid", "Same" = "solid")),
  
  # Row 3: Confidence for each task
  ggplot(combined_prop_ADT, aes(x = stimLev, group = condition, color = condition)) +
    geom_point(aes(y = ifelse(condition == "Different", diff_conf, same_conf)), size = 2) +
    geom_line(aes(y = ifelse(condition == "Different", diff_conf, same_conf)), size = 1.2) +
    ylim(2, 4) +
    ggtitle("Average of Confidence Response - ADT") +
    geom_linerange(mapping = aes(ymin = diff_conf - diff_conf_se, ymax = diff_conf + diff_conf_se, linetype = condition), data = filter(combined_prop_ADT, condition == "Different")) +
    geom_linerange(mapping = aes(ymin = same_conf - same_conf_se, ymax = same_conf + same_conf_se, linetype = condition), data = filter(combined_prop_ADT, condition == "Same")) +
    labs(caption = "Error bars represent standard error of the mean (SEM)") +
    xlab("Oddball Level") +
    ylab("Confidence Rating") +
    scale_color_manual(values = c("Different" = "#BC3C29FF",
                                  "Same" = "#0072B5FF"
    ),
    labels = c("Different",
               "Same"
    )) +
    scale_linetype_manual(values = c("Different" = "solid", "Same" = "solid")),
  
  ggplot(combined_prop_VDT, aes(x = stimLev, group = condition, color = condition)) +
    geom_point(aes(y = ifelse(condition == "Different", diff_conf, same_conf)), size = 2) +
    geom_line(aes(y = ifelse(condition == "Different", diff_conf, same_conf)), size = 1.2) +
    ylim(2, 4) +
    ggtitle("Average of Confidence Response - VDT") +
    geom_linerange(mapping = aes(ymin = diff_conf - diff_conf_se, ymax = diff_conf + diff_conf_se, linetype = condition), data = filter(combined_prop_VDT, condition == "Different")) +
    geom_linerange(mapping = aes(ymin = same_conf - same_conf_se, ymax = same_conf + same_conf_se, linetype = condition), data = filter(combined_prop_VDT, condition == "Same")) +
    labs(caption = "Error bars represent standard error of the mean (SEM)") +
    xlab("Contrast Level") +
    ylab("Confidence Rating") +
    scale_color_manual(values = c("Different" = "#BC3C29FF",
                                  "Same" = "#0072B5FF"
    ),
    labels = c("Different",
               "Same"
    )) +
    scale_linetype_manual(values = c("Different" = "solid", "Same" = "solid")),
  
  ggplot(combined_prop_CDT, aes(x = stimLev, group = condition, color = condition)) +
    geom_point(aes(y = ifelse(condition == "Different", diff_conf, same_conf)), size = 2) +
    geom_line(aes(y = ifelse(condition == "Different", diff_conf, same_conf)), size = 1.2) +
    ylim(2, 4) +
    ggtitle("Average of Confidence Response - CDT") +
    geom_linerange(mapping = aes(ymin = diff_conf - diff_conf_se, ymax = diff_conf + diff_conf_se, linetype = condition), data = filter(combined_prop_CDT, condition == "Different")) +
    geom_linerange(mapping = aes(ymin = same_conf - same_conf_se, ymax = same_conf + same_conf_se, linetype = condition), data = filter(combined_prop_CDT, condition == "Same")) +
    labs(caption = "Error bars represent standard error of the mean (SEM)") +
    xlab("Degree") +
    ylab("Confidence Rating") +
    scale_color_manual(values = c("Different" = "#BC3C29FF",
                                  "Same" = "#0072B5FF"
    ),
    labels = c("Different",
               "Same"
    )) +
    scale_linetype_manual(values = c("Different" = "solid", "Same" = "solid")),
  
  ggplot(combined_prop_MST, aes(x = stimlev_mst, group = condition, color = condition)) +
    geom_point(aes(y = ifelse(condition == "Different", diff_conf, same_conf)), size = 2) +
    geom_line(aes(y = ifelse(condition == "Different", diff_conf, same_conf)), size = 1.2) +
    ylim(2, 4) +
    ggtitle("Average of Confidence Response - MST") +
    geom_linerange(mapping = aes(ymin = diff_conf - diff_conf_se, ymax = diff_conf + diff_conf_se, linetype = condition), data = filter(combined_prop_MST, condition == "Different")) +
    geom_linerange(mapping = aes(ymin = same_conf - same_conf_se, ymax = same_conf + same_conf_se, linetype = condition), data = filter(combined_prop_MST, condition == "Same")) +
    labs(caption = "Error bars represent standard error of the mean (SEM)") +
    xlab("Similarity Level") +
    ylab("Confidence Rating") +
    scale_color_manual(values = c("Different" = "#BC3C29FF",
                                  "Same" = "#0072B5FF"
    ),
    labels = c("Different",
               "Same"
    )) +
    scale_linetype_manual(values = c("Different" = "solid", "Same" = "solid")),
  
  ncol = 4
)

# Save the grid of plots
ggsave("grid_of_plots.png", grid, width = 20, height = 15)
