import json
import math
from pathlib import Path

import matplotlib.pyplot as plt

# ============================================================
# Configuration
# ============================================================

PDD_FILE = "res/pdd_metrics.json"
GENERAL_FILE = "res/general_metrics.json"
OUTPUT_FILE = "repo_metric_boxplots.png"

# (json_key, plot_title, use_log_scale)
METRICS = [
    ("issue_body_size_average", "Средний размер тела issue", True),
    ("mean_time_to_resolution_days", "Среднее время решения (дни)", True),
    ("average_comments_per_issue", "Среднее число комментариев", False),
    ("average_events_per_issue", "Среднее число событий", False),
    ("label_rate", "Доля issue с label", False),
    ("assignee_rate", "Доля issue с исполнителем", False),
]


# ============================================================
# Helpers
# ============================================================

def load_json(path: str):
    """Load a JSON file."""
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def extract_repo_records(data):
    """
    Accept several possible JSON layouts and return a list of repository dicts.

    Supported:
      1) [ {...}, {...}, ... ]
      2) { "repositories": [ ... ] }
      3) { "data": [ ... ] }
      4) { "items": [ ... ] }
      5) { "repos": [ ... ] }
    """
    if isinstance(data, list):
        return data

    if isinstance(data, dict):
        for key in ("repositories", "data", "items", "repos"):
            if key in data and isinstance(data[key], list):
                return data[key]

    raise ValueError(
        "Unsupported JSON structure. Expected a list or a dict containing "
        "'repositories', 'data', 'items', or 'repos'."
    )


def get_numeric_metric(repo: dict, metric_name: str):
    """
    Extract a metric value from common repository JSON layouts.

    Tried in order:
      - repo[metric_name]
      - repo['metrics'][metric_name]
      - repo['repository_metrics'][metric_name]
    """
    candidates = [
        repo.get(metric_name),
        repo.get("metrics", {}).get(metric_name)
        if isinstance(repo.get("metrics"), dict) else None,
        repo.get("repository_metrics", {}).get(metric_name)
        if isinstance(repo.get("repository_metrics"), dict) else None,
    ]

    for value in candidates:
        if isinstance(value, (int, float)) and not math.isnan(value):
            return float(value)

    return None


def collect_metric_values(repos, metric_name: str):
    """Collect all non-null numeric values for a metric."""
    values = []
    for repo in repos:
        value = get_numeric_metric(repo, metric_name)
        if value is not None:
            values.append(value)
    return values


# ============================================================
# Main
# ============================================================

def main():
    pdd_path = Path(PDD_FILE)
    general_path = Path(GENERAL_FILE)

    if not pdd_path.exists():
        raise FileNotFoundError(f"Missing file: {PDD_FILE}")
    if not general_path.exists():
        raise FileNotFoundError(f"Missing file: {GENERAL_FILE}")

    pdd_raw = load_json(PDD_FILE)
    general_raw = load_json(GENERAL_FILE)

    pdd_repos = extract_repo_records(pdd_raw)
    general_repos = extract_repo_records(general_raw)

    fig, axes = plt.subplots(2, 3, figsize=(16, 9))
    axes = axes.flatten()

    for ax, (metric_key, metric_title, use_log_scale) in zip(axes, METRICS):
        pdd_values = collect_metric_values(pdd_repos, metric_key)
        general_values = collect_metric_values(general_repos, metric_key)

        if not pdd_values or not general_values:
            ax.text(
                0.5,
                0.5,
                f"No data found for:\n{metric_key}",
                ha="center",
                va="center",
                fontsize=10,
            )
            ax.set_title(metric_title)
            ax.set_xticks([1, 2])
            ax.set_xticklabels(["PDD", "General"])
            continue

        ax.boxplot(
            [pdd_values, general_values],
            labels=["PDD", "General"],
            showfliers=False,   # removes black outlier circles
            whis=1.5,
        )

        ax.set_title(metric_title)
        ax.set_ylabel("Значение")
        ax.grid(True, axis="y", linestyle="--", alpha=0.5)

        if use_log_scale:
            combined = pdd_values + general_values
            if all(v > 0 for v in combined):
                ax.set_yscale("log")
                ax.set_ylabel("Заначение (log)")


    plt.tight_layout()
    plt.savefig(OUTPUT_FILE, dpi=300, bbox_inches="tight")
    plt.show()

    print(f"Saved figure to: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()