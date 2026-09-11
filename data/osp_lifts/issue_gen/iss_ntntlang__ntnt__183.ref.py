import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("mod", Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

s = mod.enter_scope([], "global", None)
s = mod.enter_scope(s, "fn", "global")
assert mod.exit_scope(s) == ["global"]
assert mod.scope_cycle_safe({"a": "b", "b": "c"}) is True
assert mod.scope_cycle_safe({"a": "b", "b": "a"}) is False
assert mod.restore_on_exit(["g", "f", "b"], 1) == ["g"]
print("ok")
