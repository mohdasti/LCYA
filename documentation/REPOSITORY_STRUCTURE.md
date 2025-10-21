# Repository Structure

## Overview

This document describes the organization of the LCYA-Clean repository, designed for professional presentation and easy navigation.

## Directory Structure

```
LCYA-Clean/
├── README.md                    # Main repository documentation
├── LICENSE                      # MIT License
├── CONTRIBUTING.md              # Contribution guidelines
├── .gitignore                   # Git ignore rules
│
├── analysis/                    # Analysis files
│   ├── main/                   # Primary publication analysis
│   │   └── Aggregated_analysis_publication.Rmd
│   ├── manuscript_scripts/     # Scripts verified to generate manuscript results
│   └── exploratory/            # Exploratory analyses (empty, for future use)
│
├── code/                       # Analysis code
│   ├── plot_objects/          # ggplot object definitions
│   │   ├── ggplot_objects_ADT.R
│   │   ├── ggplot_objects_CDT.R
│   │   ├── ggplot_objects_dist.R
│   │   ├── ggplot_objects_MST.R
│   │   └── ggplot_objects_VDT.R
│   └── utilities/             # Helper functions and utilities
│       ├── export_plots.R
│       ├── MST_change_lures.R
│       └── plots_together.R
│
├── figures/                    # Generated figures
│   ├── publication/           # Publication-ready figures
│   │   ├── exportedplots_ADT/
│   │   ├── exportedplots_CDT/
│   │   ├── exportedplots_dist/
│   │   ├── exportedplots_MST/
│   │   └── exportedplots_VDT/
│   └── exploratory/           # Exploratory figures (empty, for future use)
│
└── documentation/             # Additional documentation
    ├── ANALYSIS_OVERVIEW.md
    ├── CODE_DOCUMENTATION.md
    ├── REPOSITORY_STRUCTURE.md
    └── results_reports/       # Markdown outputs matched to manuscript Results
```

## File Descriptions

### Core Files
- **README.md**: Main entry point with project overview, usage instructions, and key information
- **LICENSE**: MIT License for open-source distribution
- **CONTRIBUTING.md**: Guidelines for contributors
- **.gitignore**: Rules for excluding files from version control

### Analysis Files
- **analysis/main/Aggregated_analysis_publication.Rmd**: Complete analysis pipeline and results
- **analysis/exploratory/**: Directory for additional exploratory analyses

### Code Files
- **code/plot_objects/**: Contains ggplot object definitions for all tasks
- **code/utilities/**: Helper scripts for data processing and plot generation

### Figure Files
- **figures/publication/**: High-quality figures organized by task type
- **figures/exploratory/**: Directory for additional exploratory figures

### Documentation Files
- **documentation/ANALYSIS_OVERVIEW.md**: Detailed description of the study and analysis approach
- **documentation/CODE_DOCUMENTATION.md**: Technical documentation for all code files
- **documentation/REPOSITORY_STRUCTURE.md**: This file

## Design Principles

### Organization
- **Separation of Concerns**: Analysis, code, figures, and documentation are clearly separated
- **Hierarchical Structure**: Logical grouping of related files
- **Scalability**: Structure can accommodate future additions

### Naming Conventions
- **Descriptive Names**: Files and directories have clear, descriptive names
- **Consistent Patterns**: Similar files follow consistent naming patterns
- **No Abbreviations**: Avoid cryptic abbreviations in directory names

### Documentation
- **Comprehensive**: All major components are documented
- **Accessible**: Documentation is written for both technical and non-technical users
- **Maintainable**: Documentation is structured for easy updates

## Usage Guidelines

### For Researchers
1. Start with `README.md` for project overview
2. Read `documentation/ANALYSIS_OVERVIEW.md` for study details
3. Use `analysis/main/Aggregated_analysis_publication.Rmd` for main analysis
4. Refer to `documentation/CODE_DOCUMENTATION.md` for technical details

### For Contributors
1. Read `CONTRIBUTING.md` for contribution guidelines
2. Follow the established directory structure
3. Add documentation for new components
4. Update this file if adding new directories

### For Reviewers
1. Check `README.md` for completeness and accuracy
2. Verify that all code files are documented
3. Ensure figures are properly organized
4. Confirm that the structure follows best practices

## Maintenance

### Regular Updates
- Update documentation when adding new files
- Keep README.md current with project status
- Maintain consistent naming conventions
- Review and update .gitignore as needed

### Version Control
- Use meaningful commit messages
- Tag releases appropriately
- Keep the main branch clean and stable
- Use feature branches for development

## Future Considerations

### Potential Additions
- **data/**: Directory for processed data files (if needed)
- **tests/**: Unit tests for code validation
- **scripts/**: Additional automation scripts
- **reports/**: Generated reports and outputs

### Scalability
- The current structure can accommodate additional tasks
- New analysis types can be added to the exploratory directory
- Additional documentation can be added as needed
- The structure supports both individual and collaborative work
