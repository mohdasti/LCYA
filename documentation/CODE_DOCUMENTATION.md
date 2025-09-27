# Code Documentation

## File Descriptions

### Main Analysis
- **`Aggregated_analysis_publication.Rmd`**: Complete analysis pipeline including data loading, processing, statistical analysis, and visualization. This is the primary document for reproducing all results.

### Plot Objects

#### `ggplot_objects_ADT.R`
Contains ggplot objects for Auditory Discrimination Task visualizations:
- `plot1`: Proportion of "Different" vs "Same" responses by frequency level
- `plot2`: Grip strength interaction effects
- `plot3`: Median reaction times by condition
- `plot4`: Reaction time analysis with error bars
- `plot5`: Confidence ratings by condition
- `plot6`: Confidence analysis with error bars
- `plot7`: Combined accuracy and reaction time
- `plot8`: Combined accuracy and confidence

#### `ggplot_objects_VDT.R`
Contains ggplot objects for Visual Discrimination Task visualizations:
- Similar structure to ADT plots but for contrast discrimination
- Includes proportion, reaction time, and confidence analyses
- Grip strength interaction effects

#### `ggplot_objects_CDT.R`
Contains ggplot objects for Color Discrimination Task visualizations:
- Similar structure to other tasks but for color discrimination
- Degree-based stimulus levels
- All standard analyses (proportion, RT, confidence)

#### `ggplot_objects_MST.R`
Contains ggplot objects for Memory Similarity Task visualizations:
- Three-response format (Old/Similar/New)
- Memory-based similarity judgments
- Extended analysis for three response categories

#### `ggplot_objects_dist.R`
Contains distribution plots using split-violin plots:
- `plot1-2`: ADT distributions for accuracy and reaction time
- `plot3-4`: VDT distributions for accuracy and reaction time
- `plot5-6`: CDT distributions for accuracy and reaction time
- Shows grip strength effects on response distributions

### Utility Scripts

#### `export_plots.R`
- Exports all ggplot objects as PNG files
- Removes legends for publication-ready figures
- Organizes plots by task type
- Creates separate directories for each task

#### `plots_together.R`
- Creates combined multi-panel figures
- Arranges plots in grid format using `gridExtra`
- Combines accuracy, reaction time, and confidence plots
- Saves as high-resolution PNG files

#### `MST_change_lures.R`
- Processes MST lure data
- Creates quantile-based similarity levels
- Cleans image file names
- Exports processed data for analysis

## Usage Instructions

### Running the Main Analysis
1. Set working directory to the analysis folder
2. Ensure all data files are in the correct location
3. Install required packages
4. Run the RMarkdown document chunk by chunk

### Generating Figures
1. Run the main analysis to create data objects
2. Source the appropriate plot object files
3. Use `export_plots.R` to generate individual figures
4. Use `plots_together.R` to create combined figures

### Customizing Plots
- Modify color schemes in the `scale_color_manual()` functions
- Adjust plot dimensions in `ggsave()` calls
- Modify error bar calculations for different statistical approaches
- Update titles and labels for different publication requirements

## Dependencies

### Required Packages
```r
library(dplyr)          # Data manipulation
library(ggplot2)        # Plotting
library(tidyr)          # Data reshaping
library(gridExtra)      # Plot arrangement
library(cowplot)        # Plot themes
library(viridis)        # Color scales
library(ggridges)       # Distribution plots
library(raincloudplots) # Advanced distribution plots
library(report)         # Statistical reporting
```

### Data Requirements
- Trial-level behavioral data in CSV format
- Participant exclusion criteria defined
- Stimulus level definitions
- Grip strength measurements

## Troubleshooting

### Common Issues
1. **Missing data files**: Ensure CSV files are in the correct directory
2. **Package conflicts**: Check for version compatibility
3. **Memory issues**: Large datasets may require chunked processing
4. **Plot rendering**: High-resolution plots may take time to generate

### Performance Tips
- Use `cache=TRUE` in RMarkdown chunks for expensive computations
- Process data in smaller chunks for large datasets
- Save intermediate results to avoid recomputation
- Use parallel processing for bootstrap analyses
