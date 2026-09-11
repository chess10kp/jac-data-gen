import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_pathosDev__actor-ts__946",
    Path(__file__).with_name("iss_pathosDev__actor-ts__946.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_ref_store(
    [("S", {"id": "S", "n": 1})],
    [("lead", "node-1")],
)
body = {"a": "@obj:S", "b": "@obj:S", "list": ["@obj:S", "@obj:S"]}
enc = mod.encode_refs(store, body)
assert enc["a"] == {"id": "S", "n": 1}
assert enc["b"] == {"id": "S", "n": 1}
assert enc["list"] == [{"id": "S", "n": 1}, {"id": "S", "n": 1}]

dec = mod.decode_refs(store, enc)
assert dec["a"] == dec["b"]
assert dec["list"][0] == dec["list"][1]

store2 = mod.load_ref_store([("cyc", {"name": "cyc", "self": "@obj:cyc"})])
cyc_enc = mod.encode_refs(store2, {"root": "@obj:cyc"})
assert cyc_enc["root"]["self"] is None

assert mod.shared_object_ids(store, body) == ["S"]
print("ok")
