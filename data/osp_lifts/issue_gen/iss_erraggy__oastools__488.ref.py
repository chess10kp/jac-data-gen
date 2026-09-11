import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_erraggy__oastools__488", Path(__file__).with_suffix(".py")
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

# Issue repro: schema self-reference
g_self = mod.load_schema([("s", "schema")], [("s", "self", "s")])
cpy_self = mod.deep_copy(g_self, "s")
assert cpy_self["kind"] == "schema"
assert cpy_self["props"]["self"] is cpy_self
assert mod.ref_closure(g_self, "s") == []

# Issue repro: encoding self-ref under media type
g_enc = mod.load_schema(
    [("e", "encoding"), ("mt", "media")],
    [("e", "self", "e"), ("mt", "part", "e")],
)
cpy_mt = mod.deep_copy(g_enc, "mt")
part = cpy_mt["props"]["part"]
assert part["props"]["self"] is part
assert mod.ref_closure(g_enc, "mt") == ["e"]

# Acyclic copy
g_acy = mod.load_schema(
    [("root", "schema"), ("leaf", "schema")],
    [("root", "child", "leaf")],
)
cpy_acy = mod.deep_copy(g_acy, "root")
assert cpy_acy == {"kind": "schema", "props": {"child": {"kind": "schema", "props": {}}}}
assert mod.ref_closure(g_acy, "root") == ["leaf"]

# Diamond adversarial ref order
g_dia = mod.load_schema(
    [("hub", "schema"), ("left", "schema"), ("right", "schema"), ("cap", "schema")],
    [
        ("left", "to", "cap"),
        ("right", "to", "cap"),
        ("hub", "l", "left"),
        ("hub", "r", "right"),
    ],
)
assert mod.ref_closure(g_dia, "hub") == ["cap", "left", "right"]
cpy_dia = mod.deep_copy(g_dia, "hub")
assert cpy_dia["props"]["l"]["props"]["to"] is cpy_dia["props"]["r"]["props"]["to"]

# Pointer cycle a->b->c->a plus side branch
g_cyc = mod.load_schema(
    [("a", "schema"), ("b", "schema"), ("c", "schema"), ("d", "schema")],
    [("a", "n", "b"), ("b", "n", "c"), ("c", "n", "a"), ("b", "x", "d")],
)
assert mod.ref_closure(g_cyc, "a") == ["b", "c", "d"]

# Unknown id tolerance
g_solo = mod.load_schema([("solo", "schema")], [])
assert mod.deep_copy(g_solo, "nope") == {}
assert mod.ref_closure(g_solo, "nope") == []

print("ok")
