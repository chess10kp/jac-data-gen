import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_leynos__ortho-config__439",
    Path(__file__).with_name("iss_leynos__ortho-config__439.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

ConfigStore = mod.ConfigStore
CycleError = mod.CycleError
DepthError = mod.DepthError

st = ConfigStore()
st.add_config("base", ["host", "port"])
st.add_config("app", ["name"], parent="base")
st.add_config("env", ["debug"], parent="app")
assert st.resolve_layers("env", max_depth=5) == ["base", "app", "env"]
assert st.flatten_keys("env", max_depth=5) == ["host", "port", "name", "debug"]
assert st.descendant_configs("base") == ["app", "base", "env"]

try:
    cyc = ConfigStore()
    cyc.parent_of["a"] = "b"
    cyc.parent_of["b"] = "a"
    cyc.keys_of["a"] = cyc.keys_of["b"] = []
    cyc.children_of["a"] = ["b"]
    cyc.children_of["b"] = ["a"]
    cyc.resolve_layers("a", max_depth=10)
    raise SystemExit("expected CycleError")
except CycleError:
    pass

try:
    deep = ConfigStore()
    for i in range(6):
        deep.add_config("c%d" % i, ["k%d" % i], parent=("c%d" % (i - 1)) if i else None)
    deep.resolve_layers("c5", max_depth=3)
    raise SystemExit("expected DepthError")
except DepthError:
    pass

try:
    st.resolve_layers("ghost", max_depth=1)
    raise SystemExit("expected KeyError")
except KeyError:
    pass

print("ok")
