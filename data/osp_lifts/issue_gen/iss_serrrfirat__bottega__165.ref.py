import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_serrrfirat__bottega__165",
    Path(__file__).with_name("iss_serrrfirat__bottega__165.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

q = mod.load_queue(
    ["a", "b", "c"],
    [("b", "a"), ("c", "b")],
    {"a": "open", "b": "open", "c": "open"},
)
assert mod.claimable(q, "a") is True
assert mod.claimable(q, "b") is False
mod.mark_done(q, "a")
assert mod.claimable(q, "b") is True
assert mod.propagate_block(q, "b") == ["b", "c"]
assert q.status["c"] == "blocked"
assert mod.propagate_block(q, "b") == ["b"]

try:
    mod.propagate_block(q, "ghost")
    raise SystemExit("expected KeyError")
except KeyError:
    pass

print("ok")
