"""Reference harness for iss_opsmill__infrahub__8968."""
import importlib.util
import os

_here = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location(
    "before_infrahub", os.path.join(_here, "iss_opsmill__infrahub__8968.py"))
mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(mod)

h = mod.SchemaHierarchy()
h.register_kind("CoreGenericProfile")
h.register_kind("AristaGenericProfile", "CoreGenericProfile")
h.register_kind("AristaPortProfile", "AristaGenericProfile")

root = h.resolve_root("AristaPortProfile")
print("resolve_root:", root)
assert root == "CoreGenericProfile", root

line = h.lineage("AristaPortProfile")
print("lineage:", line)
assert line == ["AristaGenericProfile", "CoreGenericProfile"], line
assert h.lineage("CoreGenericProfile") == [], h.lineage("CoreGenericProfile")

kids = h.children_of("AristaGenericProfile")
print("children:", kids)
assert kids == ["AristaPortProfile"], kids

# THE #8968 shape: self-parenting kind must raise, not recurse forever.
bad = mod.SchemaHierarchy()
bad.register_kind("AristaPortProfile", None)
bad.parent_of["AristaPortProfile"] = "AristaPortProfile"  # self-reference
for fn in [lambda: bad.resolve_root("AristaPortProfile"),
           lambda: bad.lineage("AristaPortProfile")]:
    try:
        fn()
        raise SystemExit("expected SchemaCycleError")
    except mod.SchemaCycleError as exc:
        print("self-parent raises:", exc)

# Multi-hop loop also raises.
loop = mod.SchemaHierarchy()
loop.register_kind("a")
loop.register_kind("b", "a")
loop.register_kind("c", "b")
loop.parent_of["a"] = "c"
try:
    loop.resolve_root("c")
    raise SystemExit("expected SchemaCycleError")
except mod.SchemaCycleError as exc:
    print("multi-hop raises:", exc)

# Metamorphic: resolve_root(lineage-free kind) == that kind.
assert h.resolve_root("AristaGenericProfile") == "CoreGenericProfile"

print("iss_opsmill__infrahub__8968.ref: all assertions passed")
