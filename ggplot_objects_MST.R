ggplot_objects_MST <- list(
  
  plot1 = ggplot(combined_prop_MST_4T, aes(x = stimlev_mst)) +
    geom_line(aes(y = prop_old, group = condition, color = "Old"), size = 1.2) +
    geom_line(aes(y = prop_sim, group = condition, color = "Similar"), size = 1.2) +
    geom_line(aes(y = prop_new, group = condition, color = "New"), size = 1.2) +
    geom_point(aes(y = prop_old, color = "Old"), size = 2) +
    geom_point(aes(y = prop_sim, color = "Similar"), size = 2) +
    geom_point(aes(y = prop_new, color = "New"), size = 2) +
    geom_linerange(aes(ymin = prop_old - prop_old_se, ymax = prop_old + prop_old_se), color = "#0072B5FF", size = 0.5) +
    geom_linerange(aes(ymin = prop_sim - prop_sim_se, ymax = prop_sim + prop_sim_se), color = "#20854EFF", size = 0.5) +
    geom_linerange(aes(ymin = prop_new - prop_new_se, ymax = prop_new + prop_new_se), color = "#BC3C29FF", size = 0.5) +
    ggtitle("Proportions of Old, Similar, and New Responses - MST") +
    xlab("Stimulus Level") +
    ylab("Proportion") +
    labs(caption = "Error bars represent within-subject SEM") +
    scale_color_manual(values=c("Old"="#0072B5FF", "New"="#BC3C29FF", "Similar"="#20854EFF")) +
    guides(color = guide_legend(title = "Response Type")),
  
  plot2 = ggplot(combined_grip_MST_4T, aes(x = stimlev_mst, y = prop, group = condition, color = condition)) +
    geom_point(size = 2) +
    geom_line(size = 1.2) +
    geom_linerange(mapping = aes(ymin = prop - ifelse(grepl("Old", condition), prop_old_high_se, ifelse(grepl("Similar", condition), prop_sim_high_se, prop_new_high_se)),
                                 ymax = prop + ifelse(grepl("Old", condition), prop_old_high_se, ifelse(grepl("Similar", condition), prop_sim_high_se, prop_new_high_se)),
                                 color = condition),
                   show.legend = FALSE) +
    geom_linerange(mapping = aes(ymin = prop - ifelse(grepl("Old", condition), prop_old_low_se, ifelse(grepl("Similar", condition), prop_sim_low_se, prop_new_low_se)),
                                 ymax = prop + ifelse(grepl("Old", condition), prop_old_low_se, ifelse(grepl("Similar", condition), prop_sim_low_se, prop_new_low_se)),
                                 color = condition),
                   show.legend = FALSE) +
    ylim(0, 1) +
    ggtitle("Proportions of Old, Similar, and New Responses - MST_4T") +
    xlab("Similarity level") +
    ylab("Proportion") +
    labs(caption = "Error bars represent within-subject SEM") +
    scale_color_manual(values = c("New - High Grip" = "#BC3C29FF", "New - Low Grip" = "#ea9999", "Old - High Grip" = "#0072B5FF", "Old - Low Grip" = "#CCE6FF", "Similar - High Grip" = "#20854EFF", "Similar - Low Grip" = "#a7eac6")) +
    scale_linetype_manual(values = c("New - High Grip" = "solid", "New - Low Grip" = "solid", "Old - High Grip" = "solid", "Old - Low Grip" = "solid", "Similar - High Grip" = "solid", "Similar - Low Grip" = "solid")) +
    guides(color = guide_legend(title = "Response Type", ncol = 1), linetype = "none"),
  
  plot3 = ggplot(combined_medRT_MST_4T, aes(x = stimlev_mst)) +
    geom_line(aes(y = RT_old, group = condition, color = "Old"), size = 1.2) +
    geom_line(aes(y = RT_sim, group = condition, color = "Similar"), size = 1.2) +
    geom_line(aes(y = RT_new, group = condition, color = "New"), size = 1.2) +
    geom_point(aes(y = RT_old, color = "Old"), size = 2) +
    geom_point(aes(y = RT_sim, color = "Similar"), size = 2) +
    geom_point(aes(y = RT_new, color = "New"), size = 2) +
    geom_linerange(aes(ymin = RT_old - RT_old_se, ymax = RT_old + RT_old_se), color = "#0072B5FF", size = 0.5) +
    geom_linerange(aes(ymin = RT_sim - RT_sim_se, ymax = RT_sim + RT_sim_se), color = "#20854EFF", size = 0.5) +
    geom_linerange(aes(ymin = RT_new - RT_new_se, ymax = RT_new + RT_new_se), color = "#BC3C29FF", size = 0.5) +
    ggtitle("Median of Median Reaction Time for Old, Similar, and New Responses - MST") +
    xlab("Stimulus Level") +
    ylab("Median Reaction Time") +
    labs(caption = "Error bars represent within-subject SEM") +
    scale_color_manual(values=c("Old"="#0072B5FF", "New"="#BC3C29FF", "Similar"="#20854EFF")) +
    guides(color = guide_legend(title = "Response Type")),
  
  plot4 = ggplot(combined_RT_MST_4T, aes(x = stimlev_mst)) +
    geom_line(aes(y = RT_old, group = condition, color = "Old"), size = 1.2) +
    geom_line(aes(y = RT_sim, group = condition, color = "Similar"), size = 1.2) +
    geom_line(aes(y = RT_new, group = condition, color = "New"), size = 1.2) +
    geom_point(aes(y = RT_old, color = "Old"), size = 2) +
    geom_point(aes(y = RT_sim, color = "Similar"), size = 2) +
    geom_point(aes(y = RT_new, color = "New"), size = 2) +
    geom_linerange(aes(ymin = RT_old - RT_old_se, ymax = RT_old + RT_old_se), color = "#0072B5FF", size = 0.5) +
    geom_linerange(aes(ymin = RT_sim - RT_sim_se, ymax = RT_sim + RT_sim_se), color = "#20854EFF", size = 0.5) +
    geom_linerange(aes(ymin = RT_new - RT_new_se, ymax = RT_new + RT_new_se), color = "#BC3C29FF", size = 0.5) +
    ggtitle("Median of Within and Mean Between Reaction Time - MST") +
    xlab("Stimulus Level") +
    ylab("Median Reaction Time") +
    labs(caption = "Error bars represent within-subject SEM") +
    scale_color_manual(values=c("Old"="#0072B5FF", "New"="#BC3C29FF", "Similar"="#20854EFF")) +
    guides(color = guide_legend(title = "Response Type")),
  
  plot5 = ggplot(data = combined_medRT_grip_MST_4T) +
    geom_point(aes(x = stimlev_mst, y = RT_old_high, color = condition), size = 2) +
    geom_line(aes(x = stimlev_mst, y = RT_old_high, color = condition, group = condition), size = 1.2) +
    geom_linerange(aes(x = stimlev_mst, ymin = RT_old_high - RT_old_high_se, 
                       ymax = RT_old_high + RT_old_high_se, color = condition), 
                   linetype = "solid") +
    
    geom_point(aes(x = stimlev_mst, y = RT_old_low, color = condition), size = 2) +
    geom_line(aes(x = stimlev_mst, y = RT_old_low, color = condition, group = condition), size = 1.2) +
    geom_linerange(aes(x = stimlev_mst, ymin = RT_old_low - RT_old_low_se, 
                       ymax = RT_old_low + RT_old_low_se, color = condition), 
                   linetype = "solid") +
    
    geom_point(aes(x = stimlev_mst, y = RT_sim_high, color = condition), size = 2) +
    geom_line(aes(x = stimlev_mst, y = RT_sim_high, color = condition, group = condition), size = 1.2) +
    geom_linerange(aes(x = stimlev_mst, ymin = RT_sim_high - RT_sim_high_se, 
                       ymax = RT_sim_high + RT_sim_high_se, color = condition), 
                   linetype = "solid") +
    
    geom_point(aes(x = stimlev_mst, y = RT_sim_low, color = condition), size = 2) +
    geom_line(aes(x = stimlev_mst, y = RT_sim_low, color = condition, group = condition), size = 1.2) +
    geom_linerange(aes(x = stimlev_mst, ymin = RT_sim_low - RT_sim_low_se, 
                       ymax = RT_sim_low + RT_sim_low_se, color = condition), 
                   linetype = "solid") +
    
    geom_point(aes(x = stimlev_mst, y = RT_new_high, color = condition), size = 2) +
    geom_line(aes(x = stimlev_mst, y = RT_new_high, color = condition, group = condition), size = 1.2) +
    geom_linerange(aes(x = stimlev_mst, ymin = RT_new_high - RT_new_high_se, 
                       ymax = RT_new_high + RT_new_high_se, color = condition), 
                   linetype = "solid") +
    
    geom_point(aes(x = stimlev_mst, y = RT_new_low, color = condition), size = 2) +
    geom_line(aes(x = stimlev_mst, y = RT_new_low, color = condition, group = condition), size = 1.2) +
    geom_linerange(aes(x = stimlev_mst, ymin = RT_new_low - RT_new_low_se, 
                       ymax = RT_new_low + RT_new_low_se, color = condition), 
                   linetype = "solid") +
    
    
    ggtitle("Median of Reaction Time for Same and Different Responses - MST") +
    xlab("Similarity level") +
    ylab("Reaction Time") +
    labs(caption = "Error bars represent within-subject SEM") +
    scale_color_manual(values = c("New - High Grip" = "#BC3C29FF", "New - Low Grip" = "#ea9999", "Old - High Grip" = "#0072B5FF", "Old - Low Grip" = "#CCE6FF", "Similar - High Grip" = "#20854EFF", "Similar - Low Grip" = "#a7eac6")) +
    scale_linetype_manual(values = c("New - High Grip" = "solid", "New - Low Grip" = "solid", "Old - High Grip" = "solid", "Old - Low Grip" = "solid", "Similar - High Grip" = "solid", "Similar - Low Grip" = "solid")) +
    guides(color = guide_legend(title = "Response Type", ncol = 1), linetype = "none"),
  
  plot6 = ggplot(data = combined_RT_grip_MST_4T) +
    geom_point(aes(x = stimlev_mst, y = RT_old_high, color = condition), size = 2) +
    geom_line(aes(x = stimlev_mst, y = RT_old_high, color = condition, group = condition), size = 1.2) +
    geom_linerange(aes(x = stimlev_mst, ymin = RT_old_high - RT_old_high_se, 
                       ymax = RT_old_high + RT_old_high_se, color = condition), 
                   linetype = "solid") +
    
    geom_point(aes(x = stimlev_mst, y = RT_old_low, color = condition), size = 2) +
    geom_line(aes(x = stimlev_mst, y = RT_old_low, color = condition, group = condition), size = 1.2) +
    geom_linerange(aes(x = stimlev_mst, ymin = RT_old_low - RT_old_low_se, 
                       ymax = RT_old_low + RT_old_low_se, color = condition), 
                   linetype = "solid") +
    
    geom_point(aes(x = stimlev_mst, y = RT_sim_high, color = condition), size = 2) +
    geom_line(aes(x = stimlev_mst, y = RT_sim_high, color = condition, group = condition), size = 1.2) +
    geom_linerange(aes(x = stimlev_mst, ymin = RT_sim_high - RT_sim_high_se, 
                       ymax = RT_sim_high + RT_sim_high_se, color = condition), 
                   linetype = "solid") +
    
    geom_point(aes(x = stimlev_mst, y = RT_sim_low, color = condition), size = 2) +
    geom_line(aes(x = stimlev_mst, y = RT_sim_low, color = condition, group = condition), size = 1.2) +
    geom_linerange(aes(x = stimlev_mst, ymin = RT_sim_low - RT_sim_low_se, 
                       ymax = RT_sim_low + RT_sim_low_se, color = condition), 
                   linetype = "solid") +
    
    geom_point(aes(x = stimlev_mst, y = RT_new_high, color = condition), size = 2) +
    geom_line(aes(x = stimlev_mst, y = RT_new_high, color = condition, group = condition), size = 1.2) +
    geom_linerange(aes(x = stimlev_mst, ymin = RT_new_high - RT_new_high_se, 
                       ymax = RT_new_high + RT_new_high_se, color = condition), 
                   linetype = "solid") +
    
    geom_point(aes(x = stimlev_mst, y = RT_new_low, color = condition), size = 2) +
    geom_line(aes(x = stimlev_mst, y = RT_new_low, color = condition, group = condition), size = 1.2) +
    geom_linerange(aes(x = stimlev_mst, ymin = RT_new_low - RT_new_low_se, 
                       ymax = RT_new_low + RT_new_low_se, color = condition), 
                   linetype = "solid") +
    
    
    ggtitle("Median of Within and Mean Between Reaction Time - MST") +
    xlab("Similarity level") +
    ylab("Reaction Time") +
    labs(caption = "Error bars represent within-subject SEM") +
    scale_color_manual(values = c("New - High Grip" = "#BC3C29FF", "New - Low Grip" = "#ea9999", "Old - High Grip" = "#0072B5FF", "Old - Low Grip" = "#CCE6FF", "Similar - High Grip" = "#20854EFF", "Similar - Low Grip" = "#a7eac6")) +
    scale_linetype_manual(values = c("New - High Grip" = "solid", "New - Low Grip" = "solid", "Old - High Grip" = "solid", "Old - Low Grip" = "solid", "Similar - High Grip" = "solid", "Similar - Low Grip" = "solid")) +
    guides(color = guide_legend(title = "Response Type", ncol = 1), linetype = "none"),
  
  plot7 =  ggplot(combined_conf_MST_4T, aes(x = stimlev_mst)) +
    geom_line(aes(y = conf_old, group = condition, color = "Old"), size = 1.2) +
    geom_line(aes(y = conf_sim, group = condition, color = "Similar"), size = 1.2) +
    geom_line(aes(y = conf_new, group = condition, color = "New"), size = 1.2) +
    geom_point(aes(y = conf_old, color = "Old"), size = 2) +
    geom_point(aes(y = conf_sim, color = "Similar"), size = 2) +
    geom_point(aes(y = conf_new, color = "New"), size = 2) +
    geom_linerange(aes(ymin = conf_old - conf_old_se, ymax = conf_old + conf_old_se), color = "#0072B5FF", size = 0.5) +
    geom_linerange(aes(ymin = conf_sim - conf_sim_se, ymax = conf_sim + conf_sim_se), color = "#20854EFF", size = 0.5) +
    geom_linerange(aes(ymin = conf_new - conf_new_se, ymax = conf_new + conf_new_se), color = "#BC3C29FF", size = 0.5) +
    ggtitle("Average of Confidence for Old, Similar, and New Responses - MST") +
    xlab("Stimulus Level") +
    ylab("Confidence Rating") +
    ylim(2,4)+
    labs(caption = "Error bars represent within-subject SEM") +
    scale_color_manual(values=c("Old"="#0072B5FF", "New"="#BC3C29FF", "Similar"="#20854EFF")) +
    guides(color = guide_legend(title = "Response Type")),
  
  plot8 = ggplot(combined_conf_grip_MST_4T, aes(x = stimlev_mst)) +
    geom_line(aes(y = conf_high_old, group = condition, color = condition), size = 1.2) +
    geom_point(aes(y = conf_high_old, color = condition), size = 2) +
    geom_linerange(aes(ymin = conf_high_old - conf_high_old_se, ymax = conf_high_old + conf_high_old_se, color = condition), size = 0.5) +
    geom_line(aes(y = conf_high_sim, group = condition, color = condition), size = 1.2, linetype = "solid") +
    geom_point(aes(y = conf_high_sim, color = condition), size = 2) +
    geom_linerange(aes(ymin = conf_high_sim - conf_high_sim_se, ymax = conf_high_sim + conf_high_sim_se, color = condition), size = 0.5) +
    geom_line(aes(y = conf_high_new, group = condition, color = condition), size = 1.2, linetype = "solid") +
    geom_point(aes(y = conf_high_new, color = condition), size = 2) +
    geom_linerange(aes(ymin = conf_high_new - conf_high_new_se, ymax = conf_high_new + conf_high_new_se, color = condition), size = 0.5) +
    geom_line(aes(y = conf_low_old, group = condition, color = condition), size = 1.2) +
    geom_point(aes(y = conf_low_old, color = condition), size = 2) +
    geom_linerange(aes(ymin = conf_low_old - conf_low_old_se, ymax = conf_low_old + conf_low_old_se, color = condition), size = 0.5) +
    geom_line(aes(y = conf_low_sim, group = condition, color = condition), size = 1.2, linetype = "solid") +
    geom_point(aes(y = conf_low_sim, color = condition), size = 2) +
    geom_linerange(aes(ymin = conf_low_sim - conf_low_sim_se, ymax = conf_low_sim + conf_low_sim_se, color = condition), size = 0.5) +
    geom_line(aes(y = conf_low_new, group = condition, color = condition), size = 1.2, linetype = "solid") +
    geom_point(aes(y = conf_low_new, color = condition), size = 2) +
    geom_linerange(aes(ymin = conf_low_new - conf_low_new_se, ymax = conf_low_new + conf_low_new_se, color = condition), size = 0.5) +
    ggtitle("Average of Confidence for Old, Similar, and New Responses - MST") +
    xlab("Stimulus Level") +
    ylab("Confidence Rating") +
    ylim(2, 4) +
    labs(caption = "Error bars represent within-subject SEM") +
    scale_color_manual(values = c("#0072B5FF", "#CCE6FF", "#20854EFF", "#a7eac6", "#BC3C29FF", "#ea9999"),
                       name = "Condition",
                       labels = c("Old - High Grip", "Old - Low Grip", "Similar - High Grip", "Similar - Low Grip", "New - High Grip", "New - Low Grip")) +
    scale_linetype_manual(values = c("solid", "solid", "solid", "solid", "solid", "solid"), 
                          name = "Condition",
                          labels = c("Old - High Grip", "Old - Low Grip", "Similar - High Grip", "Similar - Low Grip", "New - High Grip", "New - Low Grip")) +
    guides(color = guide_legend(title = "Response Type"))
  
)