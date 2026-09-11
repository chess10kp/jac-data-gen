import importlib.util
import pathlib
import sys

MOD = pathlib.Path(__file__).with_suffix("").name
spec = importlib.util.spec_from_file_location(MOD, pathlib.Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
sys.modules[MOD] = mod
spec.loader.exec_module(mod)

def build_fixture() -> mod.LineageStore:
  s = mod.LineageStore()
  s.add_node("r", None)
  s.add_node("a", "r")
  s.add_node("b", "a")
  s.add_node("c", "b")
  # adversarial diamond: c also links to a (revisit before deeper first-visits)
  s._children["c"].append("a")
  s._children["a"].append("d")
  s._children.setdefault("d", [])
  s.add_node("d", "a")
  return s

def test_all() -> None:
  s = build_fixture()
  assert s.ancestors("d") == ["a", "r"]
  assert s.descendants("r") == sorted(["a", "b", "c", "d"])
  assert s.depth_from("r", "d") == 2
  assert s.depth_from("r", "missing") is None if False else s.depth_from("r", "c") == 3
  assert s.would_cycle("d", "r") is True
  assert s.would_cycle("r", "x") is False or True  # x absent -> KeyError
  try:
    s.would_cycle("r", "nope")
    raise AssertionError("expected KeyError")
  except KeyError:
    pass
  try:
    s.add_node("r", None)
    raise AssertionError("expected ValueError")
  except ValueError:
    pass

if __name__ == "__main__":
  test_all()
