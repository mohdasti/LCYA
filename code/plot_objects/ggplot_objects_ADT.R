ggplot_objects_ADT <- list(
  plot1 = ggplot(combined_ADT_4T, aes(x = stimLev, y = prop, group = condition, color = condition)) +
    geom_point(size = 2) +
    geom_line(size = 1.2) +
    geom_linerange(mapping = aes(ymin = prop - ifelse(condition == "Different", diff_se, not_diff_se), 
                                 ymax = prop + ifelse(condition == "Different", diff_se, not_diff_se))) +
    ylim(0, 1) +
    ggtitle("Proportion of Responding 'Different' and 'Same' - ADT'") +
    xlab("Oddball Level (Hz)") +
    ylab("Proportion") +
    labs(caption = "Error bars represent within-subject SEM") +
    scale_color_manual(values = c("#BC3C29FF", "#0072B5FF")) +
    guides(color = guide_legend(title = "condition")),
  
  plot2 = ggplot(combined_grip_ADT_4T, aes(x = stimLev, y = prop, group = condition, color = condition)) +
    geom_point( size = 2) +
    geom_line(size = 1.2) +
    geom_linerange(mapping = aes(ymin = prop - ifelse(condition == "Different - High Grip" | condition == "Different - Low Grip", diff_se, not_diff_se), 
                                 ymax = prop + ifelse(condition == "Different - High Grip" | condition == "Different - Low Grip", diff_se, not_diff_se)), show.legend = FALSE) +
    ylim(0, 1) +
    ggtitle("Proportion of Responding 'Different' and 'Same' - ADT'") +
    xlab("Oddball Level (Hz)") +
    ylab("Proportion") +
    labs(caption = "Error bars represent within-subject SEM") +
    scale_color_manual(values = c("Different - High Grip" = "#BC3C29FF", "Different - Low Grip" = "#ea9999", "Same - High Grip" = "#0072B5FF", "Same - Low Grip" = "#CCE6FF")) +
    scale_linetype_manual(values = c("Different - High Grip" = "solid", "Different - Low Grip" = "solid", "Same - High Grip" = "solid", "Same - Low Grip" = "solid")) +
    guides(color = guide_legend(title = "Response Type", ncol = 1), linetype = "none"),
  
  plot3 = ggplot(combined_medRT_ADT_4T, aes(x = stimLev, group = condition, color = condition, linetype= condition)) +
    geom_point(aes(y = ifelse(condition == "Different", medRT_diff , medRT_same)), size = 2) +
    geom_line(aes(y = ifelse(condition == "Different", medRT_diff, medRT_same)), size = 1.2) +
    ylim(min(c(combined_medRT_ADT_4T$medRT_diff, combined_medRT_ADT_4T$medRT_same)), max(c(combined_medRT_ADT_4T$medRT_diff, combined_medRT_ADT_4T$medRT_same))) +
    ggtitle("Median of Reaction Time for Same and Different Responses - ADT") +
    geom_linerange(mapping = aes(ymin = medRT_diff - medRT_diff_se, ymax = medRT_diff + medRT_diff_se, linetype = condition), data = filter(combined_medRT_ADT_4T, condition == "Different")) +
    geom_linerange(mapping = aes(ymin = medRT_same - medRT_same_se, ymax = medRT_same + medRT_same_se, linetype = condition), data = filter(combined_medRT_ADT_4T, condition == "Same")) +
    labs(caption = "Error bars represent within-subject SEM") +
    xlab("Oddball Level (Hz)") +
    ylab("Reaction Time (S)") +
    scale_color_manual(values = c( "#BC3C29FF", "#0072B5FF")) +
    scale_linetype_manual(values = c("Different" = "solid", "Same" = "solid")),
  
  plot4 = ggplot(combined_RT_ADT_4T, aes(x = stimLev, group = condition, color = condition, linetype= condition)) +
    geom_point(aes(y = ifelse(condition == "Different", medRT_diff , medRT_same)), size = 2) +
    geom_line(aes(y = ifelse(condition == "Different", medRT_diff, medRT_same)), size = 1.2) +
    ylim(min(c(combined_RT_ADT_4T$medRT_diff, combined_RT_ADT_4T$medRT_same)), max(c(combined_RT_ADT_4T$medRT_diff, combined_RT_ADT_4T$medRT_same))) +
    ggtitle("Median of Reaction Time within and Mean between - ADT") +
    geom_linerange(mapping = aes(ymin = medRT_diff - medRT_diff_se, ymax = medRT_diff + medRT_diff_se, linetype = condition), data = filter(combined_RT_ADT_4T, condition == "Different")) +
    geom_linerange(mapping = aes(ymin = medRT_same - medRT_same_se, ymax = medRT_same + medRT_same_se, linetype = condition), data = filter(combined_RT_ADT_4T, condition == "Same")) +
    labs(caption = "Error bars represent within-subject SEM") +
    xlab("Oddball Level (Hz)") +
    ylab("Reaction Time (S)") +
    scale_color_manual(values = c( "#BC3C29FF", "#0072B5FF")) +
    scale_linetype_manual(values = c("Different" = "solid", "Same" = "solid")),
  
  plot5 = ggplot(data = combined_medRT_grip_ADT_4T) +
    geom_point(aes(x = stimLev, y = medRT_high_diff, color = condition), size = 2) +
    geom_line(aes(x = stimLev, y = medRT_high_diff, color = condition, group = condition), size = 1.2) +
    geom_linerange(aes(x = stimLev, ymin = medRT_high_diff - medRT_high_diff_se, 
                       ymax = medRT_high_diff + medRT_high_diff_se, color = condition), 
                   linetype = "solid") +
    
    geom_point(aes(x = stimLev, y = medRT_low_diff, color = condition), size = 2) +
    geom_line(aes(x = stimLev, y = medRT_low_diff, color = condition, group = condition), size = 1.2) +
    geom_linerange(aes(x = stimLev, ymin = medRT_low_diff - medRT_low_diff_se, 
                       ymax = medRT_low_diff + medRT_low_diff_se, color = condition), 
                   linetype = "solid") +
    
    geom_point(aes(x = stimLev, y = medRT_high_same, color = condition), size = 2) +
    geom_line(aes(x = stimLev, y = medRT_high_same, color = condition, group = condition), size = 1.2) +
    geom_linerange(aes(x = stimLev, ymin = medRT_high_same - medRT_high_same_se, 
                       ymax = medRT_high_same + medRT_high_same_se, color = condition), 
                   linetype = "solid") +
    
    geom_point(aes(x = stimLev, y = medRT_low_same, color = condition), size = 2) +
    geom_line(aes(x = stimLev, y = medRT_low_same, color = condition, group = condition), size = 1.2) +
    geom_linerange(aes(x = stimLev, ymin = medRT_low_same - medRT_low_same_se, 
                       ymax = medRT_low_same + medRT_low_same_se, color = condition), 
                   linetype = "solid") +
    
    ggtitle("Median of Reaction Time for Same and Different Responses - ADT") +
    xlab("Oddball Level (Hz)") +
    ylab("Reaction Time") +
    labs(caption = "Error bars represent within-subject SEM") +
    scale_color_manual(values = c("#BC3C29FF", "#ea9999", "#0072B5FF", "#CCE6FF"),
                       name = "Condition"),
  
  plot6 = ggplot(data = combined_RT_grip_ADT_4T) +
    geom_point(aes(x = stimLev, y = medRT_high_diff, color = condition), size = 2) +
    geom_line(aes(x = stimLev, y = medRT_high_diff, color = condition, group = condition), size = 1.2) +
    geom_linerange(aes(x = stimLev, ymin = medRT_high_diff - medRT_high_diff_se, 
                       ymax = medRT_high_diff + medRT_high_diff_se, color = condition), 
                   linetype = "solid") +
    
    geom_point(aes(x = stimLev, y = medRT_low_diff, color = condition), size = 2) +
    geom_line(aes(x = stimLev, y = medRT_low_diff, color = condition, group = condition), size = 1.2) +
    geom_linerange(aes(x = stimLev, ymin = medRT_low_diff - medRT_low_diff_se, 
                       ymax = medRT_low_diff + medRT_low_diff_se, color = condition), 
                   linetype = "solid") +
    
    geom_point(aes(x = stimLev, y = medRT_high_same, color = condition), size = 2) +
    geom_line(aes(x = stimLev, y = medRT_high_same, color = condition, group = condition), size = 1.2) +
    geom_linerange(aes(x = stimLev, ymin = medRT_high_same - medRT_high_same_se, 
                       ymax = medRT_high_same + medRT_high_same_se, color = condition), 
                   linetype = "solid") +
    
    geom_point(aes(x = stimLev, y = medRT_low_same, color = condition), size = 2) +
    geom_line(aes(x = stimLev, y = medRT_low_same, color = condition, group = condition), size = 1.2) +
    geom_linerange(aes(x = stimLev, ymin = medRT_low_same - medRT_low_same_se, 
                       ymax = medRT_low_same + medRT_low_same_se, color = condition), 
                   linetype = "solid") +
    
    ggtitle("Median of Reaction Time Within and Mean Between - ADT") +
    xlab("Oddball Level (Hz)") +
    ylab("Reaction Time") +
    labs(caption = "Error bars represent within-subject SEM") +
    scale_color_manual(values = c("#BC3C29FF", "#ea9999", "#0072B5FF", "#CCE6FF"),
                       name = "Condition"),
  
  plot7 = ggplot(combined_prop_ADT_4T, aes(x = stimLev, group = condition, color = condition)) +
    geom_point(aes(y = ifelse(condition == "Different", diff_conf, same_conf)), size = 2) +
    geom_line(aes(y = ifelse(condition == "Different", diff_conf, same_conf)), size = 1.2) +
    ylim(2, 4) +
    ggtitle("Average of Confidence Response - ADT") +
    geom_linerange(mapping = aes(ymin = diff_conf - diff_conf_se, ymax = diff_conf + diff_conf_se, linetype = condition), data = filter(combined_prop_ADT_4T, condition == "Different")) +
    geom_linerange(mapping = aes(ymin = same_conf - same_conf_se, ymax = same_conf + same_conf_se, linetype = condition), data = filter(combined_prop_ADT_4T, condition == "Same")) +
    labs(caption = "Error bars represent within-subject SEM") +
    xlab("Oddball Level") +
    ylab("Confidence Rating") +
    scale_color_manual(values = c("Different" = "#BC3C29FF",
                                  "Same" = "#0072B5FF"
    ),
    labels = c("Different",
               "Same"
    )) +
    scale_linetype_manual(values = c("Different" = "solid", "Same" = "solid")),
  
  plot8 = ggplot(combined_conf_grip_ADT_4T, aes(x = stimLev, color = condition)) +
    geom_point(aes(y = diff_high_conf), size = 3) +
    geom_line(aes(y = diff_high_conf, group = condition), size = 1.2) +
    geom_linerange(aes(ymin = diff_high_conf - diff_high_conf_se, 
                       ymax = diff_high_conf + diff_high_conf_se, group = condition), 
                   width = 0.2, linetype = "solid") +
    geom_point(aes(y = diff_low_conf), size = 3) +
    geom_line(aes(y = diff_low_conf, group = condition), size = 1.2, linetype = "solid") +
    geom_linerange(aes(ymin = diff_low_conf - diff_low_conf_se, 
                       ymax = diff_low_conf + diff_low_conf_se, group = condition), 
                   width = 0.2, linetype = "solid") +
    geom_point(aes(y = same_high_conf), size = 3) +
    geom_line(aes(y = same_high_conf, group = condition), size = 1.2) +
    geom_linerange(aes(ymin = same_high_conf - same_high_conf_se, 
                       ymax = same_high_conf + same_high_conf_se, group = condition), 
                   linetype = "solid") +
    geom_point(aes(y = same_low_conf), size = 3) +
    geom_line(aes(y = same_low_conf, group = condition), size = 1.2, linetype = "solid") +
    geom_linerange(aes(ymin = same_low_conf - same_low_conf_se, 
                       ymax = same_low_conf + same_low_conf_se, group = condition), 
                   width = 0.2, linetype = "solid") +
    ggtitle("Average of Confidence Response - ADT") +
    labs(caption = "Error bars represent within-subject SEM", x = "Oddball Level", y = "Confidence Rating") +
    scale_color_manual(values = c("#BC3C29FF", "#ea9999", "#0072B5FF", "#CCE6FF"),
                       name = "Response Type") +
    ylim(2,4)+
    scale_linetype_manual(values = c("solid", "solid"), name = "Condition",
                          labels = c("High Grip", "Low Grip"))
)

