# Issue: Feed generation fails on timezone-offset dates in frontmatter

The feed builder is currently producing malformed JSON when markdown posts include `date` values with timezone offsets (examples: `2026-01-10T09:30:00-05:00`, `2026-01-10T14:30:00+00:00`).

What we need fixed:

- `scripts/build_feed.py` should keep all valid posts in the output array.
- Date parsing needs to correctly handle ISO-8601 timestamps with timezone offsets.
- Output entries must keep stable ordering by published date descending.
- The generated JSON must preserve required keys and types for downstream consumers.
- Invalid or incomplete frontmatter should be skipped safely without crashing.

Artifacts in this repo:

- `content/posts/*.md` sample markdown posts.
- `scripts/build_feed.py` current feed generator.
- Expected output shape is a JSON object with a `posts` array.

Acceptance expectation:

- Running the test suite should pass once the bug is fixed.
- Keep implementation clean and maintainable; do not hardcode specific fixture filenames.
