import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("iss_zackees__zccache__1099", Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

DAG = [("compile", "link"), ("link", "test"), ("compile", "lint")]
CYCLE = [("a", "b"), ("b", "c"), ("c", "a")]

assert mod.build_order(DAG) == ["compile", "link", "lint", "test"]
assert mod.workflow_reachable("compile", DAG) == ["compile", "link", "lint", "test"]
assert mod.build_order(CYCLE) == []
assert mod.workflow_reachable("missing", DAG) == []
print("ok")
