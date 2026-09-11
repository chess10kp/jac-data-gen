import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_AppAppWorks__tycho__3",
    Path(__file__).with_name("iss_AppAppWorks__tycho__3.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

DagStore = mod.DagStore

st = DagStore()
st.add_node("S")
st.add_node("NP", parent="S")
st.add_node("VP", parent="S")
st.add_node("N", parent="NP")
st.add_node("V", parent="VP")
assert st.dominates("S", "N") is True
assert st.dominates("NP", "V") is False
assert st.ancestors("N") == ["NP", "S"]

CYC = DagStore()
CYC.parent_of["a"] = "b"
CYC.parent_of["b"] = "a"
CYC.children_of["a"] = ["b"]
CYC.children_of["b"] = ["a"]
assert CYC.ancestors("a") == ["b"]

try:
    st.ancestors("ghost")
    raise SystemExit("expected KeyError")
except KeyError:
    pass

assert st.dominates("missing", "N") is False

print("ok")
