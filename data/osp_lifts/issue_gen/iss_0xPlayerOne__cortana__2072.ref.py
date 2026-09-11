import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_cortana_2072",
    Path(__file__).with_name("iss_0xPlayerOne__cortana__2072.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_code_graph(
    ["main", "util", "io", "deep"],
    [("main", "util"), ("util", "io"), ("io", "deep")],
)
assert mod.neighborhood(g, "main", 1) == ["main", "util"]
assert mod.neighborhood(g, "main", 3) == ["deep", "io", "main", "util"]

g_d = mod.load_code_graph(
    ["hub", "left", "right", "bot"],
    [("right", "bot"), ("hub", "left"), ("left", "bot"), ("hub", "right")],
)
assert mod.neighborhood(g_d, "hub", 2) == ["bot", "hub", "left", "right"]
print("ok")
