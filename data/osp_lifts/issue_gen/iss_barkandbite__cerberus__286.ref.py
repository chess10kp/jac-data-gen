"""Reference harness: exercises every public function of iss_barkandbite__cerberus__286."""
import importlib.util
import sys
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "cb286", Path(__file__).parent / "iss_barkandbite__cerberus__286.py"
)
mod = importlib.util.module_from_spec(spec)
sys.modules["cb286"] = mod
spec.loader.exec_module(mod)

pool = mod.StyleSheetPool()
inliner = mod.Inliner(pool, max_depth=4, max_fetches=1000)

pool.register("/a.css", ".a {}", ["/b.css", "/c.css"])
pool.register("/b.css", ".b {}", ["/d.css"])
pool.register("/c.css", ".c {}", [])
pool.register("/d.css", ".d {}", [])

assert inliner.inline_closure("/a.css") == ["/b.css", "/c.css", "/d.css"]
# Each URL fetched exactly once despite fan-out.
assert pool.fetch_count("/a.css") == 1
assert pool.fetch_count("/b.css") == 1
assert pool.fetch_count("/d.css") == 1
assert inliner.total_bytes("/a.css") == 15  # three 5-char bodies in closure

# Repeat import of the same URL: fetched once (the issue's N^4 killer).
p2 = mod.StyleSheetPool()
i2 = mod.Inliner(p2, max_depth=4, max_fetches=1000)
p2.register("/hub.css", ".hub {}", ["/leaf.css"] * 20 + ["/hub2.css"])
p2.register("/hub2.css", "", ["/leaf.css", "/leaf.css"])
p2.register("/leaf.css", ".leaf {}", [])
assert i2.inline_closure("/hub.css") == ["/hub2.css", "/leaf.css"]
assert p2.fetch_count("/leaf.css") == 1
assert p2.fetch_count("/hub.css") == 1

# Cycle a -> b -> a terminates via the visited set.
p3 = mod.StyleSheetPool()
i3 = mod.Inliner(p3, max_depth=8)
p3.register("/a.css", "", ["/b.css"])
p3.register("/b.css", "", ["/a.css"])
assert i3.inline_closure("/a.css") == ["/b.css"]

# Depth cap: chain longer than max_depth stops fetching.
p4 = mod.StyleSheetPool()
i4 = mod.Inliner(p4, max_depth=4)
prev = "/deep9.css"
p4.register(prev, ".x {}", [])
for i in range(9, -1, -1):
    p4.register("/deep{}.css".format(i), ".x {}", ["/deep{}.css".format(i + 1)])
closure = i4.inline_closure("/deep0.css")
assert len(closure) <= 4, closure

# Budget exhaustion raises BudgetExceeded.
p5 = mod.StyleSheetPool()
i5 = mod.Inliner(p5, max_depth=10, max_fetches=3)
for i in range(10):
    p5.register("/s{}.css".format(i), "", ["/s{}.css".format(i + 1)])
try:
    i5.inline_closure("/s0.css")
    raise AssertionError("expected BudgetExceeded")
except mod.BudgetExceeded:
    pass

# Unknown URL fails closed.
try:
    inliner.inline_closure("/ghost.css")
    raise AssertionError("expected KeyError")
except KeyError:
    pass

print("cerberus 286 ref OK")
