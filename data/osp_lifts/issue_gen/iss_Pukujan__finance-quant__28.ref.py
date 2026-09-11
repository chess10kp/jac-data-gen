"""Reference harness for iss_Pukujan__finance-quant__28."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_Pukujan__finance-quant__28.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
reg = new_registry()
register_component(reg, "a", "price", "s-a", "i-a")
register_component(reg, "b", "fundamentals", "s-b", "i-b")
register_component(reg, "c", "news", "s-c", "i-c")
register_component(reg, "d", "rag", "s-d", "i-d")
assert add_dependency(reg, "a", "c")
assert add_dependency(reg, "a", "b")
assert add_dependency(reg, "b", "d")
assert add_dependency(reg, "c", "d")
assert sorted(descendants(reg, "a")) == ["a", "b", "c", "d"]
assert sorted(invalidation_plan(reg, "a")) == ["b", "c", "d"]

reg = new_registry()
assert descendants(reg, "missing") == []
assert invalidation_plan(reg, "missing") == []
assert add_dependency(reg, "missing", "also-missing") is False
assert cache_lookup(reg, "missing-artifact") is False

reg = new_registry()
first = request_artifact(reg, "price-v1", "price", "code-1", "input-1")
second = request_artifact(reg, "price-v1", "price", "code-1", "input-1")
assert first == second
assert cache_lookup(reg, first)

reg = new_registry()
old_hash = request_artifact(reg, "news-v1", "news", "code-1", "input-1")
new_hash = request_artifact(reg, "news-v1", "news", "code-1", "input-2")
assert old_hash != new_hash
assert cache_lookup(reg, old_hash)
assert cache_lookup(reg, new_hash)

reg = new_registry()
a = request_artifact(reg, "a", "price", "s-a", "i-a")
b = request_artifact(reg, "b", "rag", "s-b", "i-b")
first = build_manifest(reg, ["b", "a"])
same = build_manifest(reg, ["a", "b"])
assert first == same
request_artifact(reg, "b", "rag", "s-b", "i-b-2")
changed = build_manifest(reg, ["a", "b"])
assert changed != first
assert cache_lookup(reg, a)
assert cache_lookup(reg, b)
assert add_dependency(reg, "a", "missing") is False
print("iss_Pukujan__finance-quant__28 ref OK")
