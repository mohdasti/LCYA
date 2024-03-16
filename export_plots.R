source("ggplot_objects_ADT.R")

# Specify full path to the directory
export_dir <- "~/R/LCYA_trial_level/exportedplots_ADT"

# Check if the directory exists, if not, create it
if (!dir.exists(export_dir)) {
  dir.create(export_dir, recursive = TRUE)
}

# Iterate over ggplot objects
for (plot_name in names(ggplot_objects_ADT)) {
  # Remove legend from the plot
  ggplot_objects_ADT[[plot_name]] <- ggplot_objects_ADT[[plot_name]] + theme(legend.position = "none")
  
  # Export the plot as a PNG file
  ggsave(filename = paste0(export_dir, "/", plot_name, ".png"), plot = ggplot_objects_ADT[[plot_name]], width = 6, height = 4)
}

####

source("ggplot_objects_VDT.R")

# Specify full path to the directory
export_dir <- "~/R/LCYA_trial_level/exportedplots_VDT"

# Check if the directory exists, if not, create it
if (!dir.exists(export_dir)) {
  dir.create(export_dir, recursive = TRUE)
}

# Iterate over ggplot objects
for (plot_name in names(ggplot_objects_VDT)) {
  # Remove legend from the plot
  ggplot_objects_VDT[[plot_name]] <- ggplot_objects_VDT[[plot_name]] + theme(legend.position = "none")
  
  # Export the plot as a PNG file
  ggsave(filename = paste0(export_dir, "/", plot_name, ".png"), plot = ggplot_objects_VDT[[plot_name]], width = 6, height = 4)
}


####
source("ggplot_objects_CDT.R")

# Specify full path to the directory
export_dir <- "~/R/LCYA_trial_level/exportedplots_CDT"

# Check if the directory exists, if not, create it
if (!dir.exists(export_dir)) {
  dir.create(export_dir, recursive = TRUE)
}

# Iterate over ggplot objects
for (plot_name in names(ggplot_objects_CDT)) {
  # Remove legend from the plot
  ggplot_objects_CDT[[plot_name]] <- ggplot_objects_CDT[[plot_name]] + theme(legend.position = "none")
  
  # Export the plot as a PNG file
  ggsave(filename = paste0(export_dir, "/", plot_name, ".png"), plot = ggplot_objects_CDT[[plot_name]], width = 6, height = 4)
}


####

source("ggplot_objects_MST.R")

# Specify full path to the directory
export_dir <- "~/R/LCYA_trial_level/exportedplots_MST"

# Check if the directory exists, if not, create it
if (!dir.exists(export_dir)) {
  dir.create(export_dir, recursive = TRUE)
}

# Iterate over ggplot objects
for (plot_name in names(ggplot_objects_MST)) {
  # Remove legend from the plot
  ggplot_objects_MST[[plot_name]] <- ggplot_objects_MST[[plot_name]] + theme(legend.position = "none")
  
  # Export the plot as a PNG file
  ggsave(filename = paste0(export_dir, "/", plot_name, ".png"), plot = ggplot_objects_MST[[plot_name]], width = 6, height = 4)
}

#####
source("ggplot_objects_dist.R")

# Specify full path to the directory
export_dir <- "~/R/LCYA_trial_level/exportedplots_dist"

# Check if the directory exists, if not, create it
if (!dir.exists(export_dir)) {
  dir.create(export_dir, recursive = TRUE)
}

# Iterate over ggplot objects
for (plot_name in names(ggplot_objects_distributions)) {
  # Remove legend from the plot
  ggplot_objects_distributions[[plot_name]] <- ggplot_objects_distributions[[plot_name]] + theme(legend.position = "none")
  
  # Export the plot as a PNG file
  ggsave(filename = paste0(export_dir, "/", plot_name, ".png"), plot = ggplot_objects_distributions[[plot_name]], width = 6, height = 4)
}

