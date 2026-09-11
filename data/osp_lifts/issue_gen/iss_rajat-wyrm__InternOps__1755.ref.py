import importlib.util
from pathlib import Path
spec = importlib.util.spec_from_file_location("m", Path(__file__).with_name("iss_rajat-wyrm__InternOps__1755.py"))
mod = importlib.util.module_from_spec(spec); assert spec.loader; spec.loader.exec_module(mod)
g = mod.load_team({"a": "boss", "b": "a", "c": "b"})
assert mod.team_members(g, "boss") == ["a", "b", "c"]
g2 = mod.load_team({"a": "b", "b": "a"})
assert mod.team_members(g2, "a", ) == ["b"]  # depth cap terminates cycle
assert mod.would_cycle(g, "a", "c")
print("ok")
