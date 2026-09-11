"""Reference harness for iss_arnaud18o5__sysml-ai-copilot__33."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_arnaud18o5__sysml-ai-copilot__33.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_arnaud18o5__sysml-ai-copilot__33.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

load_element_graph = _mod.load_element_graph
impact_analysis = _mod.impact_analysis
impact_paths = _mod.impact_paths

g = load_element_graph(
    ["root", "left", "right", "join"],
    [],
    [("join", "right"), ("root", "right"), ("join", "left"), ("root", "left")],
    [],
)
assert impact_analysis(g, "root") == ["join", "left", "right"]
assert impact_analysis(g, "join") == ["left", "right", "root"]
assert impact_analysis(g, "root", max_depth=1) == ["left", "right"]

g = load_element_graph(
    ["u1", "u2", "t"],
    [("u2", "t"), ("u1", "t")],
    [],
    [],
)
assert impact_analysis(g, "u1") == ["t", "u2"]
assert impact_analysis(g, "t") == ["u1", "u2"]
assert impact_paths(g, "u1", "u2") == [["u1", "t", "u2"]]

g = load_element_graph(["only"], [], [], [])
assert impact_analysis(g, "missing") == []
assert impact_paths(g, "only", "ghost") == []
assert impact_paths(g, "ghost", "only") == []
g2 = load_element_graph(
    ["only"],
    [("only", "ghost")],
    [("phantom", "only")],
    [("specter", "only")],
)
assert impact_analysis(g2, "only") == []
assert g2["adj"]["only"] == []

g = load_element_graph(
    ["a", "b", "c"],
    [],
    [("a", "b"), ("b", "c"), ("c", "a")],
    [],
)
assert impact_paths(g, "a", "a") == [["a"]]
assert impact_paths(g, "a", "c", max_depth=2) == [["a", "c"]]
assert impact_paths(g, "a", "c", max_depth=3) == [["a", "b", "c"], ["a", "c"]]
assert impact_analysis(g, "a") == ["b", "c"]

g = load_element_graph(
    ["a", "b", "c", "d"],
    [],
    [("b", "d"), ("a", "c"), ("a", "b"), ("c", "d")],
    [],
)
assert impact_paths(g, "a", "d") == [["a", "b", "d"], ["a", "c", "d"]]
assert impact_paths(g, "d", "a") == [["d", "b", "a"], ["d", "c", "a"]]

g = load_element_graph(
    ["x", "y", "z"],
    [("x", "z"), ("x", "z")],
    [("x", "y"), ("y", "x")],
    [("y", "z")],
)
assert impact_analysis(g, "x", max_depth=0) == []
assert impact_analysis(g, "x", max_depth=2) == ["y", "z"]
assert g["adj"]["x"] == ["z", "y"]
assert g["adj"]["y"] == ["x", "z"]

print("iss_arnaud18o5__sysml-ai-copilot__33 ref OK")
print("iss_arnaud18o5__sysml-ai-copilot__33 ref OK")
