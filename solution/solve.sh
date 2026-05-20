#!/usr/bin/env bash
set -euo pipefail

mkdir -p /app/scripts

cat << 'PYEOF' > /app/scripts/build_feed.py
#!/usr/bin/env python3
import json
import os
from datetime import datetime
from typing import Dict, List, Optional, Tuple


def parse_frontmatter(text: str) -> Tuple[Optional[Dict[str, str]], str]:
    if not text.startswith("---\n"):
        return None, text

    parts = text.split("\n---\n", 1)
    if len(parts) != 2:
        return None, text

    raw = parts[0].replace("---\n", "", 1)
    body = parts[1]

    metadata: Dict[str, str] = {}
    for line in raw.splitlines():
        if not line.strip() or ":" not in line:
            continue
        key, value = line.split(":", 1)
        metadata[key.strip()] = value.strip().strip('"').strip("'")

    return metadata, body


def parse_date(date_value: str) -> Optional[datetime]:
    if not isinstance(date_value, str):
        return None
    try:
        normalized = date_value.strip().replace("Z", "+00:00")
        return datetime.fromisoformat(normalized)
    except ValueError:
        return None


def build_feed(content_dir: str) -> Dict[str, List[Dict[str, str]]]:
    posts: List[Dict[str, object]] = []

    if not os.path.isdir(content_dir):
        return {"posts": []}

    for filename in sorted(os.listdir(content_dir)):
        if not filename.endswith(".md"):
            continue

        path = os.path.join(content_dir, filename)

        try:
            with open(path, "r", encoding="utf-8") as handle:
                raw = handle.read()

            metadata, body = parse_frontmatter(raw)
            if not metadata:
                continue

            title = metadata.get("title")
            slug = metadata.get("slug")
            date_value = metadata.get("date")
            published = metadata.get("published", "true").strip().lower() == "true"

            if not title or not slug or not date_value or not published:
                continue

            published_dt = parse_date(date_value)
            if published_dt is None:
                continue

            summary = body.strip().split("\n\n", 1)[0].strip()

            posts.append(
                {
                    "title": title,
                    "slug": slug,
                    "published_at": date_value,
                    "summary": summary,
                    "_published_dt": published_dt,
                }
            )
        except Exception:
            continue

    posts.sort(key=lambda post: post["_published_dt"], reverse=True)

    return {
        "posts": [
            {
                "title": post["title"],
                "slug": post["slug"],
                "published_at": post["published_at"],
                "summary": post["summary"],
            }
            for post in posts
        ]
    }


def main() -> None:
    app_root = os.path.dirname(os.path.dirname(__file__))
    content_dir = os.path.join(app_root, "content", "posts")

    output_payload = build_feed(content_dir)

    output_dir = os.path.join(app_root, "output")
    os.makedirs(output_dir, exist_ok=True)

    output_path = os.path.join(output_dir, "feed.json")
    with open(output_path, "w", encoding="utf-8") as handle:
        json.dump(output_payload, handle, indent=2)

    print(json.dumps(output_payload, indent=2))


if __name__ == "__main__":
    main()
PYEOF

chmod +x /app/scripts/build_feed.py
