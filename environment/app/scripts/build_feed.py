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
    # BUG: strips timezone and truncates by fixed format; fails on offsets like -05:00
    # and returns None for many valid ISO inputs.
    if not isinstance(date_value, str):
        return None
    try:
        return datetime.strptime(date_value, "%Y-%m-%dT%H:%M:%SZ")
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
            # current behavior drops valid offset timestamps
            continue

        summary = body.strip().split("\n\n", 1)[0].strip()

        posts.append(
            {
                "title": title,
                "slug": slug,
                "published_at": date_str,
                "summary": summary,
            }
        )

    # BUG: sort by string, not normalized datetime
    posts.sort(key=lambda p: p["published_at"], reverse=True)

    return {"posts": posts}


if __name__ == "__main__":
    base = os.path.dirname(os.path.dirname(__file__))
    content = os.path.join(base, "content", "posts")
    output = build_feed(content)
    print(json.dumps(output, indent=2))
