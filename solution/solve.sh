#!/usr/bin/env bash
set -euo pipefail

mkdir -p /app/scripts

cat > /app/scripts/build_feed.py <<'PYEOF'
#!/usr/bin/env python3
import json
import os
from datetime import datetime


def parse_frontmatter(text: str):
    if not text.startswith("---\n"):
        return None, text

    parts = text.split("\n---\n", 1)
    if len(parts) != 2:
        return None, text

    raw = parts[0].replace("---\n", "", 1)
    body = parts[1]

    meta = {}
    for line in raw.splitlines():
        if not line.strip() or ":" not in line:
            continue
        key, value = line.split(":", 1)
        meta[key.strip()] = value.strip().strip('"').strip("'")

    return meta, body


def parse_date(date_value: str):
    if not isinstance(date_value, str):
        return None
    try:
        return datetime.fromisoformat(date_value.strip().replace("Z", "+00:00"))
    except Exception:
        return None


def build_feed(content_dir: str):
    posts = []

    for filename in sorted(os.listdir(content_dir)):
        if not filename.endswith(".md"):
            continue

        path = os.path.join(content_dir, filename)
        with open(path, "r", encoding="utf-8") as f:
            raw = f.read()

        try:
            meta, body = parse_frontmatter(raw)
            if not meta:
                continue

            title = meta.get("title")
            slug = meta.get("slug")
            date_str = meta.get("date")
            published = meta.get("published", "true").lower() == "true"

            if not title or not slug or not date_str or not published:
                continue

            parsed = parse_date(date_str)
            if parsed is None:
                continue

            summary = body.strip().split("\n\n", 1)[0].strip()

            posts.append(
                {
                    "title": title,
                    "slug": slug,
                    "published_at": date_str,
                    "summary": summary,
                    "_published_dt": parsed,
                }
            )
        except Exception as exc:
            print(f"warning: skipping {filename}: {exc}")
            continue

    posts.sort(key=lambda p: p["_published_dt"], reverse=True)

    normalized_posts = [
        {
            "title": p["title"],
            "slug": p["slug"],
            "published_at": p["published_at"],
            "summary": p["summary"],
        }
        for p in posts
    ]

    return {"posts": normalized_posts}


if __name__ == "__main__":
    base = os.path.dirname(os.path.dirname(__file__))
    content = os.path.join(base, "content", "posts")
    output = build_feed(content)
    print(json.dumps(output, indent=2))
PYEOF

chmod +x /app/scripts/build_feed.py
