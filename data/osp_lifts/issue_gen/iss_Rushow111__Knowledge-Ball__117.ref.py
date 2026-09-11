import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_Rushow111__Knowledge-Ball__117",
    Path(__file__).with_name("iss_Rushow111__Knowledge-Ball__117.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

versions = [
    ("v3", "page"),
    ("v2", "draft"),
    ("v1", "seed"),
    ("lib", "shared"),
    ("alt", "fork"),
]
depends = [
    ("v3", "v2"),
    ("v3", "lib"),
    ("v2", "v1"),
    ("alt", "lib"),
]
lineage = [
    ("v3", "v2"),
    ("v2", "v1"),
]
g = mod.load_kvop(versions, depends, lineage)

assert mod.lineage_ancestors(g, "v3") == ["v1", "v2"]
assert mod.lineage_ancestors(g, "v1") == []
assert mod.lineage_ancestors(g, "ghost") == []

assert mod.dep_closure(g, "v3") == ["lib", "v1", "v2"]
assert mod.dep_closure(g, "alt") == ["lib"]
assert mod.dep_closure(g, "ghost") == []

assert mod.audit_reachable(g, "v3", "v1") is True
assert mod.audit_reachable(g, "v3", "lib") is True
assert mod.audit_reachable(g, "v1", "v3") is False
assert mod.audit_reachable(g, "ghost", "v3") is False

assert mod.has_dep_cycle(g) is False

assert mod.audit_closure(g, "v3") == ["lib", "v1", "v2", "v3"]

# adversarial depends insertion order (revisit before deep first-visit)
adv_versions = [("hub", "h"), ("left", "l"), ("right", "r"), ("join", "j")]
adv_depends = [("hub", "join"), ("hub", "left"), ("left", "join"), ("hub", "right"), ("right", "join")]
g_adv = mod.load_kvop(adv_versions, adv_depends, [])
assert mod.dep_closure(g_adv, "hub") == ["join", "left", "right"]
assert mod.audit_reachable(g_adv, "hub", "join") is True

# depends cycle must not truncate closure
cyc_versions = [("a", ""), ("b", ""), ("c", ""), ("d", "")]
cyc_depends = [("a", "b"), ("b", "c"), ("c", "a"), ("b", "d")]
g_cyc = mod.load_kvop(cyc_versions, cyc_depends, [])
assert mod.has_dep_cycle(g_cyc) is True
assert mod.dep_closure(g_cyc, "a") == ["b", "c", "d"]

print("ok")
