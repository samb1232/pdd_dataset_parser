# Workflow 2: Enrich and Split PDD Issues

This workflow takes a flat list of extracted puzzles, enriches them with extensive metadata directly from the GitHub API, splits them into per-project files, and then calculates statistical metrics for the issues and projects.

## Scripts

1. **`1_parser_append_info_from_github_api.rb`**: Adds `labels`, `assignees`, `comments`, and `issue_events` from the GitHub API. Uses checkpointing.
2. **`2_parser_split_by_project.rb`**: Flattens nested GitHub metadata and splits issues across individual GitHub repository JSON files.
3. **`3_enrich_projects.rb`**: Enriches project-specific JSON files with repository-level GitHub API data (language, stars, forks, contributors).
4. **`4_remove_0odd_and_calculate_issue_stats.rb`**: Removes `0pdd` comments and events, then calculates resolution time, comment counts, and event counts.

## Inputs

- The output from Workflow 0: `puzzle_related_data_from_xml.json` (usually moved to `res/puzzle_related_data_from_xml.json`).

## Outputs

- `res/enriched_tickets.json`
- `res/pdd_issues_split_by_project/*.json`
- `res/pdd_issues_split_enrich/*.json`
- `res/pdd_issues_with_stats/*.json`: The final enriched and calculated dataset per project.

## Example Usage

```bash
ruby -I../.. 1_parser_append_info_from_github_api.rb
ruby -I../.. 2_parser_split_by_project.rb
GITHUB_TOKEN=your_token ruby 3_enrich_projects.rb
ruby 4_calculate_issue_stats.rb
```
