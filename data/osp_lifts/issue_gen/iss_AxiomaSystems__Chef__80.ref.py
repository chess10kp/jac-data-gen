import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("mod", Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

TASKS = ["lint", "test", "build", "deploy"]
DEPS = [("lint", "test"), ("test", "build"), ("build", "deploy")]
OWNERS = {"lint": "qa", "test": "qa", "build": "eng", "deploy": "ops"}

assert mod.execution_order(TASKS, DEPS) == ["lint", "test", "build", "deploy"]
assert mod.hardening_ready("build", {"lint", "test"}, DEPS) is True
assert mod.hardening_ready("build", {"lint"}, DEPS) is False
by_owner = mod.tasks_by_owner(OWNERS)
assert by_owner == {"eng": ["build"], "ops": ["deploy"], "qa": ["lint", "test"]}
print("ok")
