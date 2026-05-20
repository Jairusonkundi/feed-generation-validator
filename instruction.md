Feed generation is dropping valid published posts when frontmatter `date` values include timezone offsets.

Observed behavior:
- Running `python /app/scripts/build_feed.py` returns fewer posts than expected.
- Timestamps like `2026-01-10T09:30:00-05:00` and `2026-01-10T14:30:00+00:00` are treated as invalid.
- Sort order is currently based on string comparison instead of actual datetime values.

Required fix:
1. Update `/app/scripts/build_feed.py` so ISO-8601 timestamps with offsets are accepted.
2. Keep skipping malformed or incomplete frontmatter safely.
3. Preserve output schema: root object with `posts` array; each post contains `title`, `slug`, `published_at`, `summary`.
4. Sort published posts by real datetime descending.
5. Do not hardcode fixture names; iterate source files generally.

Acceptance criteria:
- `bash /tests/test.sh` fails before changes and passes after applying your fix.
- Output remains valid JSON and stable for downstream consumers.
