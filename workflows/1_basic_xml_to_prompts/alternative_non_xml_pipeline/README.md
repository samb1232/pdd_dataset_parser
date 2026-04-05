# Workflow 3: Alternative Non-XML Pipeline

An alternative grouping workflow used for datasets that do not originate from XML parsing.

## Scripts
- **`1_parser_json_group_by_repos.rb`**: Groups puzzles by repository and time-windows while filtering for comment-rich puzzles.

## Inputs
- `dataset.json` (expected in the root directory).

## Outputs
- `dataset_group_by_repos.json`

## Example Usage
```bash
ruby -I../.. 1_parser_json_group_by_repos.rb
```
