"""Reference harness: exercises every public function of rec_12."""
from rec_12_web_crawler import build_web, crawl, frontier_at_limit

web = build_web(
    ["home", "/a", "/b", "/c", "/d", "dead"],
    [
        ("home", "/a", "read"),
        ("/a", "/b", "next"),
        ("/b", "/c", "next"),
        ("/c", "/d", "next"),
        ("/c", "/a", "back"),   # cycle back into budget
        ("/d", "/a", "home"),   # cycle
    ],
)

assert crawl(web, "home", 0) == ["home"]
assert crawl(web, "home", 2) == ["/a", "/b", "home"]
assert crawl(web, "home", 10) == ["/a", "/b", "/c", "/d", "home"]

# Frontier pins exact hop levels.
assert frontier_at_limit(web, "home", 0) == ["home"]
assert frontier_at_limit(web, "home", 3) == ["/c"]

# Unknown start url -> empty (source convention).
assert crawl(web, "missing", 3) == []
assert frontier_at_limit(web, "missing", 2) == []

# Cycle safety: pure cycle must terminate.
ring = build_web(["x", "y"], [("x", "y", "l"), ("y", "x", "l")])
assert crawl(ring, "x", 99) == ["x", "y"]

print("rec_12 ref OK")
