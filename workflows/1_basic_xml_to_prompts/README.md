# Workflow 1: Basic XML to Prompts

This workflow takes extracted puzzle data and formats it into prompts suitable for Large Language Models (LLMs) to perform prioritization tasks.

## Scripts
1. **`1_parser_json_for_xml.rb`**: Groups puzzles from an XML-derived JSON file into time-windows centered around closed puzzles.
2. **`2_parser_to_chronographic.rb`**: Normalizes and re-indexes puzzle collections chronologically, stripping unnecessary fields.
3. **`3_prompt_maker.rb`**: Creates the final LLM prioritization prompt JSON.

## Inputs
- The output from Workflow 0: `dataset_from_xml.json` (usually moved to `results/dataset_from_xml.json`).

## Outputs
- `dataset_xml_by_timestamps.json`: Grouped puzzles by time-window.
- `dataset_simple_chronographic.json`: Chronologically sorted and simplified puzzles.
- `prompts_for_long_explaining.json`: The final prompt dataset for LLMs.

## Example Usage
```bash
ruby -I../.. 1_parser_json_for_xml.rb
ruby -I../.. 2_parser_to_chronographic.rb
ruby -I../.. 3_prompt_maker.rb
```
