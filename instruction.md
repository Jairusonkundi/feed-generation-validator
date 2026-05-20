`/app/scripts/build_feed.py` — three bugs:

**date parsing** — strptime with `%Y-%m-%dT%H:%M:%SZ`, blows up on real tz offsets. `2026-01-10T09:30:00-05:00` → returns None → post silently dropped. fix: fromisoformat

**sort** — string sort on date field, not datetime. order breaks when mixing offset formats

**bad frontmatter** → whole script crashes. needs to skip that file and keep going

---

json output shape (frontend breaks silently if wrong):
```json
{
  "posts": [
    {
      "title": "...",
      "slug": "...",
      "published_at": "2026-01-10T09:30:00-05:00",
      "summary": "..."
    }
  ]
}
```
root object, `posts` key, array — each item exactly those 4 fields, nothing extra

---

only `/app/scripts/build_feed.py`, don't touch tests/
