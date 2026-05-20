import json
import subprocess
from datetime import datetime


def run_builder():
    proc = subprocess.run(
        ["python", "/app/scripts/build_feed.py"],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(proc.stdout)


def to_dt(value: str) -> datetime:
    if value.endswith("Z"):
        value = value[:-1] + "+00:00"
    return datetime.fromisoformat(value)


def test_output_root_object_shape():
    data = run_builder()
    assert isinstance(data, dict)
    assert "posts" in data
    assert isinstance(data["posts"], list)


def test_timezone_offset_posts_are_included():
    data = run_builder()
    slugs = {p["slug"] for p in data["posts"]}
    assert "alpha-release" in slugs
    assert "bravo-update" in slugs
    assert "charlie-note" in slugs


def test_unpublished_post_is_excluded():
    data = run_builder()
    slugs = {p["slug"] for p in data["posts"]}
    assert "draft-internal" not in slugs


def test_invalid_frontmatter_is_skipped():
    data = run_builder()
    slugs = {p["slug"] for p in data["posts"]}
    assert "invalid-missing-date" not in slugs


def test_posts_have_required_fields_and_types():
    data = run_builder()
    for post in data["posts"]:
        assert set(post.keys()) == {"title", "slug", "published_at", "summary"}
        assert isinstance(post["title"], str) and post["title"]
        assert isinstance(post["slug"], str) and post["slug"]
        assert isinstance(post["published_at"], str) and post["published_at"]
        assert isinstance(post["summary"], str)


def test_posts_sorted_by_actual_datetime_descending():
    data = run_builder()
    dts = [to_dt(p["published_at"]) for p in data["posts"]]
    assert dts == sorted(dts, reverse=True)


def test_expected_post_count():
    data = run_builder()
    assert len(data["posts"]) == 3
