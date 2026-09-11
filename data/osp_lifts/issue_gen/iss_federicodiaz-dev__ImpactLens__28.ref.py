import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_federicodiaz-dev__ImpactLens__28",
    Path(__file__).with_name("iss_federicodiaz-dev__ImpactLens__28.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

load_graph = mod.load_graph
affected_files = mod.affected_files
affected_paths = mod.affected_paths

LINEAR = load_graph(
    ["util.py", "model.py", "service.py", "cli.py"],
    [
        ("service.py", "model.py"),
        ("model.py", "util.py"),
        ("cli.py", "service.py"),
    ],
)
assert affected_paths(LINEAR, ["util.py"]) == ["cli.py", "model.py", "service.py"]
assert affected_files(LINEAR, ["util.py"], max_depth=1) == [("model.py", 1)]

CYCLE = load_graph(
    ["a.py", "b.py", "c.py", "d.py"],
    [
        ("a.py", "b.py"),
        ("b.py", "c.py"),
        ("c.py", "a.py"),
        ("c.py", "d.py"),
    ],
)
assert affected_paths(CYCLE, ["b.py"]) == ["a.py", "c.py"]

DIAMOND = load_graph(
    ["core.py", "left.py", "right.py", "app.py"],
    [
        ("left.py", "core.py"),
        ("right.py", "core.py"),
        ("app.py", "left.py"),
        ("app.py", "right.py"),
    ],
)
assert affected_paths(DIAMOND, ["core.py"]) == ["app.py", "left.py", "right.py"]

MULTI = load_graph(
    ["x.py", "y.py", "z.py"],
    [("y.py", "x.py"), ("z.py", "x.py")],
)
assert affected_paths(MULTI, ["x.py", "y.py"]) == ["z.py"]

assert affected_paths(LINEAR, ["missing.py"]) == []
assert affected_paths(LINEAR, ["util.py"], max_depth=0) == []

print("ok")
