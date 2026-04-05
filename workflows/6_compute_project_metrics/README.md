# Workflow 6: Compute Project Metrics

This workflow computes high-level, repository-wide summary metrics for any generated JSON dataset (e.g. `pdd_issues_with_stats` or `general_gh_project_info`).

## Scripts
- **`1_compute_metrics.rb`**: Iterates through a target directory full of repository JSON files. It aggregates text body length averages, calculates label and assignee ratios, resolves time-to-close metrics, and outputs everything as a unified statistical flat array. Excludes specific `pdd` tags from its labeling score by default.
- **`2_aggregate_metrics.rb`**: An aggregation script running on the outputs of the main `1_compute_metrics.rb` tool. It collapses all the repository-level metrics into summary indicators (mean, median, interquartile range, standard deviation, min, and max). 
- **`2_compare_groups_mannwhitney.py`**: A statistical Python script that compares the repository-level metric arrays of two different datasets (e.g., PDD vs General) using the Mann-Whitney U test. It calculates p-values, Bonferroni-corrected significance, and Cliff's Delta effect sizes, and saves the results to a specified JSON file.

## Inputs
- `1_compute_metrics.rb`: A directory containing GitHub repository JSON metric files.
- `2_aggregate_metrics.rb`: The combined json file output from `1_compute_metrics.rb`.
- `2_compare_groups_mannwhitney.py`: Two JSON files containing repository-level metrics arrays (e.g., `pdd_metrics.json` and `general_metrics.json`).

## Outputs
- A cross-repository statistical metrics JSON summary matching your desired filename. 
- A JSON file containing the results of the Mann-Whitney U test and Cliff's Delta calculations.

## Example Usage
```bash
ruby 1_compute_metrics.rb ../../res/pdd_issues_with_stats/ ../../res/pdd_metrics.json
ruby 2_aggregate_metrics.rb ../../res/pdd_metrics.json ../../res/pdd_metrics_summary.json
python 2_compare_groups_mannwhitney.py ../../res/pdd_metrics.json ../../res/general_metrics.json ../../res/mannwhitney_results.json
```
