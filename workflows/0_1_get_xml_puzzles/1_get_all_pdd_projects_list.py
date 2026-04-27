import json
import requests

user = "0pdd"
page = 1
urls = []

while True:
    response = requests.get(
        f"https://api.github.com/users/{user}/starred",
        params={"per_page": 100, "page": page},
        headers={
            "Accept": "application/vnd.github+json",
        },
        timeout=30,
    )
    response.raise_for_status()

    repos = response.json()
    if not repos:
        break

    urls.extend(repo["full_name"] for repo in repos)
    page += 1

# Save results as JSON array file
with open("pdd_starred_projects.json", "w") as f:
    json.dump(urls, f, indent=2)

print(f"Successfully saved {len(urls)} projects to pdd_starred_projects.json")