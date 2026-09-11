import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("mod", Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

DEPS = {"parse": ["typecheck"], "typecheck": ["codegen"], "codegen": ["emit"]}
PARENT = {"leaf": "mid", "mid": "root"}

assert mod.invalidate_stages("parse", DEPS) == ["parse", "typecheck", "codegen", "emit"]
assert mod.memo_ancestors("leaf", PARENT) == ["mid", "root"]
hit, val = mod.provider_utility_hit({"k": 42}, "k")
assert hit is True and val == 42
miss, val2 = mod.provider_utility_hit({}, "missing")
assert miss is False and val2 is None
print("ok")
