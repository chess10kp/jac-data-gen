"""Reference harness for iss_cue-lang__cue__2555."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_cue-lang__cue__2555.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_cue-lang__cue__2555.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

load_package = _mod.load_package
resolve_load_order = _mod.resolve_load_order
transitive_field_refs = _mod.transitive_field_refs
cyclic_reference_fields = _mod.cyclic_reference_fields
export_package = _mod.export_package
kube_reproducer = _mod.kube_reproducer

diamond = load_package(
    [("a.cue", {}), ("b.cue", {}), ("c.cue", {}), ("d.cue", {})],
    [("a.cue", "b.cue"), ("a.cue", "c.cue"), ("b.cue", "d.cue"), ("c.cue", "d.cue")],
)
assert transitive_field_refs(diamond, "a.cue") == ["b.cue", "c.cue", "d.cue"]
assert transitive_field_refs(diamond, "d.cue") == []
assert cyclic_reference_fields(diamond) == []
assert resolve_load_order(diamond) == ["a.cue", "b.cue", "c.cue", "d.cue"]

solo_pkg = load_package(
    [("solo.cue", {})],
    [("solo.cue", "ghost.cue"), ("ghost.cue", "solo.cue"), ("phantom.cue", "solo.cue")],
)
assert transitive_field_refs(solo_pkg, "solo.cue") == []
assert transitive_field_refs(solo_pkg, "missing.cue") == []
assert cyclic_reference_fields(solo_pkg) == []
assert export_package(solo_pkg) == {"deployment": {}, "oAuthProxy": {}}
assert "ghost.cue" not in solo_pkg.files
assert solo_pkg.refs.get("solo.cue", []) == ["ghost.cue"]

pkg_z = kube_reproducer(rename_z_to_a=False)
pkg_a = kube_reproducer(rename_z_to_a=True)
ok_z = export_package(pkg_z, ["c.cue", "b.cue", "z.cue"])
ok_a = export_package(pkg_a, ["c.cue", "b.cue", "a.cue"])
assert isinstance(ok_z, dict)
assert isinstance(ok_a, dict)
assert ok_z["deployment"] == {"prometheus-proxy": "proxy"}
assert ok_a["deployment"] == {"prometheus-proxy": "proxy"}
assert ok_z["oAuthProxy"] == {"prometheus": "prometheus"}
assert ok_a["oAuthProxy"] == {"prometheus": "prometheus"}

multi = load_package(
    [
        ("comp.cue", {"oauth_comp": True}),
        ("inst.cue", {"instances": {"z1": "zebra", "a1": "apple", "m1": "middle"}}),
    ],
    [],
)
out = export_package(multi, ["inst.cue", "comp.cue"])
assert out == {
    "deployment": {
        "apple-proxy": "proxy",
        "middle-proxy": "proxy",
        "zebra-proxy": "proxy",
    },
    "oAuthProxy": {"a1": "apple", "m1": "middle", "z1": "zebra"},
}

loop_pkg = load_package([("loop.cue", {})], [("loop.cue", "loop.cue")])
assert transitive_field_refs(loop_pkg, "loop.cue") == []
assert cyclic_reference_fields(loop_pkg) == ["loop.cue"]
print("iss_cue-lang__cue__2555 ref OK")
