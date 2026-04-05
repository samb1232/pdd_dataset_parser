import json
import sys
from pathlib import Path

import numpy as np
from scipy import stats


METRICS_TO_TEST = [
    "issue_body_size_average",
    "mean_time_to_resolution_days",
    "average_comments_per_issue",
    "average_events_per_issue",
    "label_rate",
    "assignee_rate",
]


def load_json_file(path_str):
    path = Path(path_str)
    if not path.exists():
        raise FileNotFoundError(f"Input file does not exist: {path}")
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, list):
        raise ValueError(f"Input JSON must be a list of repository objects: {path}")
    return data


def is_valid_numeric(value):
    if value is None or isinstance(value, bool):
        return False
    if isinstance(value, (int, float, np.integer, np.floating)):
        return bool(np.isfinite(value))
    return False


def extract_metric_values(repositories, metric_name):
    values = []
    for repo in repositories:
        if not isinstance(repo, dict):
            continue
        value = repo.get(metric_name)
        if is_valid_numeric(value):
            values.append(float(value))
    return values


def compute_cliffs_delta(group_a, group_b):
    """
    Cliff's delta:
    delta = (number of pairs where a > b - number of pairs where a < b) / (n1 * n2)
    Ties are ignored in the numerator.
    """
    n1 = len(group_a)
    n2 = len(group_b)

    if n1 == 0 or n2 == 0:
        return None

    a = np.asarray(group_a, dtype=float)[:, None]
    b = np.asarray(group_b, dtype=float)[None, :]

    greater = np.sum(a > b)
    less = np.sum(a < b)

    delta = (greater - less) / (n1 * n2)
    return float(delta)


def interpret_cliffs_delta(delta):
    abs_delta = abs(delta)
    if abs_delta < 0.147:
        return "negligible"
    if abs_delta < 0.33:
        return "small"
    if abs_delta < 0.474:
        return "medium"
    return "large"


def cliffs_delta_direction(delta):
    if delta > 0:
        return "pdd_higher"
    if delta < 0:
        return "general_higher"
    return "no_difference"


def safe_round(value, digits=4):
    if value is None:
        return None
    return round(float(value), digits)


def format_p_value_for_stdout(p_value):
    if p_value is None:
        return "NA"
    if p_value < 0.0001:
        return "<0.0001"
    return f"{p_value:.4f}"


def analyze_metric(metric_name, pdd_values, general_values, bonferroni_alpha):
    n_pdd = len(pdd_values)
    n_general = len(general_values)

    if n_pdd < 2 or n_general < 2:
        return {
            "pdd_count": n_pdd,
            "general_count": n_general,
            "error": "Not enough valid observations in one or both groups to run Mann-Whitney U test"
        }

    pdd_mean = float(np.mean(pdd_values))
    general_mean = float(np.mean(general_values))
    pdd_median = float(np.median(pdd_values))
    general_median = float(np.median(general_values))

    u_statistic, p_value = stats.mannwhitneyu(
        pdd_values,
        general_values,
        alternative="two-sided",
        method="asymptotic"
    )

    delta = compute_cliffs_delta(pdd_values, general_values)

    if pdd_median > general_median:
        higher_median_group = "pdd"
    elif general_median > pdd_median:
        higher_median_group = "general"
    else:
        higher_median_group = "equal"

    return {
        "pdd_count": n_pdd,
        "general_count": n_general,
        "pdd_mean": safe_round(pdd_mean),
        "general_mean": safe_round(general_mean),
        "pdd_median": safe_round(pdd_median),
        "general_median": safe_round(general_median),
        "higher_median_group": higher_median_group,
        "u_statistic": safe_round(u_statistic),
        "p_value": float(p_value),
        "p_value_rounded": safe_round(p_value),
        "significant_at_0_05": bool(p_value < 0.05),
        "bonferroni_alpha": safe_round(bonferroni_alpha, 6),
        "significant_bonferroni": bool(p_value < bonferroni_alpha),
        "cliffs_delta": safe_round(delta),
        "cliffs_delta_interpretation": interpret_cliffs_delta(delta),
        "cliffs_delta_direction": cliffs_delta_direction(delta),
    }


def print_summary(results):
    print("Mann-Whitney U test summary")
    print("-" * 80)
    for metric, result in results["tests"].items():
        if "error" in result:
            print(
                f"{metric}: insufficient data "
                f"(pdd_count={result['pdd_count']}, general_count={result['general_count']})"
            )
            continue

        print(
            f"{metric}: "
            f"median(PDD)={result['pdd_median']}, "
            f"median(General)={result['general_median']}, "
            f"higher_median={result['higher_median_group']}, "
            f"U={result['u_statistic']}, "
            f"p={format_p_value_for_stdout(result['p_value'])}, "
            f"sig_0.05={result['significant_at_0_05']}, "
            f"sig_bonf={result['significant_bonferroni']}, "
            f"delta={result['cliffs_delta']} "
            f"({result['cliffs_delta_interpretation']}, {result['cliffs_delta_direction']})"
        )


def main():
    if len(sys.argv) != 4:
        print(
            "Usage: python compare_groups_mannwhitney.py "
            "<pdd_metrics.json> <general_metrics.json> <output.json>"
        )
        sys.exit(1)

    pdd_file = sys.argv[1]
    general_file = sys.argv[2]
    output_file = sys.argv[3]

    try:
        pdd_data = load_json_file(pdd_file)
        general_data = load_json_file(general_file)
    except Exception as e:
        print(f"Error loading input files: {e}")
        sys.exit(1)

    bonferroni_alpha = 0.05 / len(METRICS_TO_TEST)

    results = {
        "input_files": {
            "pdd": str(Path(pdd_file)),
            "general": str(Path(general_file)),
        },
        "tests": {}
    }

    for metric in METRICS_TO_TEST:
        pdd_values = extract_metric_values(pdd_data, metric)
        general_values = extract_metric_values(general_data, metric)

        results["tests"][metric] = analyze_metric(
            metric,
            pdd_values,
            general_values,
            bonferroni_alpha
        )

    try:
        with Path(output_file).open("w", encoding="utf-8") as f:
            json.dump(results, f, indent=2)
    except Exception as e:
        print(f"Error writing output file: {e}")
        sys.exit(1)

    print_summary(results)
    print("-" * 80)
    print(f"Results written to {output_file}")


if __name__ == "__main__":
    main()