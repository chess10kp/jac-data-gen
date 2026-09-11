import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_SalarAI__Nova__6",
    Path(__file__).with_name("iss_SalarAI__Nova__6.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.Graph()
for nid, lbl in [("a", "A"), ("b", "B"), ("c", "C"), ("d", "D")]:
  mod.add_node(g, nid, lbl)
mod.add_edge(g, "a", "b")
mod.add_edge(g, "a", "c")
mod.add_edge(g, "b", "d")
mod.add_edge(g, "c", "d")
mod.add_edge(g, "d", "a")

assert mod.bfs_order(g, "a") == ["a", "b", "c", "d"]
assert mod.dfs_order(g, "a") == ["a", "b", "c", "d"]
assert mod.is_reachable(g, "a", "d") is True
assert mod.is_reachable(g, "d", "b") is True
assert mod.has_cycle(g) is True

g2 = mod.Graph()
for nid in ["hub", "left", "right", "sink"]:
  mod.add_node(g2, nid)
mod.add_edge(g2, "hub", "left")
mod.add_edge(g2, "hub", "right")
mod.add_edge(g2, "left", "sink")
mod.add_edge(g2, "right", "sink")
mod.add_edge(g2, "sink", "left")
assert mod.bfs_order(g2, "hub") == ["hub", "left", "right", "sink"]
assert mod.bfs_order(g2, "ghost") == []

try:
  mod.add_edge(g2, "hub", "ghost")
  raise AssertionError("expected GraphError")
except mod.GraphError:
  pass

print("ok")
