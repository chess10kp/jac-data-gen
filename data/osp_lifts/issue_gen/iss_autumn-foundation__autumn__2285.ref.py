import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_autumn-foundation__autumn__2285",
    Path(__file__).with_name("iss_autumn-foundation__autumn__2285.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_comments(
    ["recA", "recB"],
    [("c1", "recA"), ("c2", "recA"), ("c3", "recA"), ("c4", "recB")],
    [("c2", "c1"), ("c3", "c2")],
    [("recA", 3), ("recB", 1)],
)
removed = mod.delete_comment(store, "recA", "c1")
assert removed == ["c1", "c2", "c3"]
assert mod.comment_count(store, "recA") == 0
assert mod.remaining_comments(store, "recB") == ["c4"]

store2 = mod.load_comments(
    ["recA", "recB"],
    [("root", "recA"), ("orphan", "recB")],
    [("orphan", "root")],
    [("recA", 1), ("recB", 1)],
)
assert mod.cross_record_orphans(store2, "recB") == ["orphan"]
print("ok")
