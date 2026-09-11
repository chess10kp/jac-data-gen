import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_compendium_53",
    Path(__file__).with_name("iss_brylie__compendium__53.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

rs = mod.load_entities(["doc_a", "doc_b", "doc_c"])
mod.create_ref(rs, "doc_a", "doc_b", "references")
mod.create_ref(rs, "doc_c", "doc_a", "derives_from")
assert mod.forward_refs(rs, "doc_a") == [("doc_b", "references")]
assert mod.reverse_refs(rs, "doc_a") == [("doc_c", "derives_from")]
mod.retire_ref(rs, "doc_a", "doc_b", "references")
assert mod.forward_refs(rs, "doc_a") == []
assert mod.forward_refs(rs, "ghost") == []
print("ok")
