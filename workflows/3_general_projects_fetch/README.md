# Workflow 5: General Projects Collection

This standalone workflow generates issue statistics for a broad selection of standard GitHub projects, operating independently of the PDD context.

## Scripts
- **`1_fetch_general_projects_info.rb`**: Fetches issues (up to 400 within 2023-2024), comments, and events directly from the GitHub API and builds a structured dataset identical to the PDD enriched results. Includes checkpointing and rate limit handling.

## Inputs
- `../../gh_scripts/300_selected_projects.json`

## Outputs
- `res/general_gh_project_info/*.json`: One JSON file per repository containing issues and standard GitHub metadata.

## Example Usage
```bash
GITHUB_TOKEN=your_token ruby 1_fetch_general_projects_info.rb
```
