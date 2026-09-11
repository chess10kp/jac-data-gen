import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod586",
    Path(__file__).with_name("iss_beyond-immersion__bannou-service__586.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_tags(
    ["furniture", "chair", "table", "leg"],
    [("furniture", "chair"), ("furniture", "table"), ("table", "leg")],
)
assert mod.expand_tags(store, "furniture") == ["chair", "leg", "table"]
assert mod.would_create_cycle(store, "leg", "furniture") is True
assert mod.add_tag_relation(store, "leg", "furniture") is False
assert mod.add_tag_relation(store, "chair", "stool") is False
store2 = mod.load_tags(["a", "b"], [])
assert mod.add_tag_relation(store2, "a", "b") is True
assert mod.expand_tags(store2, "a") == ["b"]
print("ok")
