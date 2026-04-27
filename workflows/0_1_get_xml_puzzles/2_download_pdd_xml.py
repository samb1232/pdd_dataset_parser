import json
import os
import time
import requests

# Create output directory
os.makedirs("pdd_xml", exist_ok=True)

# Load project list
with open("pdd_starred_projects.json", "r") as f:
    projects = json.load(f)

print(f"Loading XML puzzles for {len(projects)} projects...")

for i, full_name in enumerate(projects, 1):
    # Create safe filename from full_name (replace / with _)
    safe_name = full_name.replace("/", "_")
    output_path = f"pdd_xml/{safe_name}.xml"

    # Skip if already downloaded
    if os.path.exists(output_path):
        print(f"[{i}/{len(projects)}] Skipping {full_name} (already exists)")
        continue

    try:
        # Download XML
        response = requests.get(
            f"https://www.0pdd.com/xml?name={full_name}",
            timeout=30,
        )
        response.raise_for_status()

        # Save to file
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(response.text)

        print(f"[{i}/{len(projects)}] Downloaded {full_name}")

        # Be nice to the server
        time.sleep(0.5)

    except requests.exceptions.RequestException as e:
        print(f"[{i}/{len(projects)}] Error downloading {full_name}: {e}")
        continue

print(f"\nCompleted! XML files saved in pdd_xml/ folder")
