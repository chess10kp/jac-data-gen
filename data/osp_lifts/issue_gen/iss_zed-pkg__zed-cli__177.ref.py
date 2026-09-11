import importlib.util
from pathlib import Path

HERE = Path(__file__).resolve().parent
MOD = HERE / "iss_zed-pkg__zed-cli__177.py"

spec = importlib.util.spec_from_file_location("zed_submod", MOD)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

PARENT = {"vendor/lib": "vendor", "vendor": "."}
assert mod.submodule_order(["vendor/lib", "vendor"], PARENT) == ["vendor", "vendor/lib"]

CHILDREN = {
    "vendor": ["vendor/lib"],
    "vendor/lib": ["vendor/lib/deep"],
}
assert mod.submodule_closure("vendor", CHILDREN) == [
    "vendor",
    "vendor/lib",
    "vendor/lib/deep",
]

# Adversarial children list order: shared target reachable before deeper branches.
DIAMOND = {
    "d0": ["t", "a", "b"],
    "a": ["t"],
    "b": ["t"],
}
got = mod.submodule_closure("d0", DIAMOND)
assert got.count("t") == 1
assert got == ["d0", "t", "a", "b"]

assert mod.submodule_cycle_safe({"a": "b", "b": "a"}) is False
assert mod.submodule_cycle_safe({"vendor/lib": "vendor"}) is True

try:
    mod.submodule_order(["a", "b"], {"a": "b", "b": "a"})
    raise AssertionError("expected ValueError")
except ValueError:
    pass

assert mod.submodule_order(["solo"], {}) == ["solo"]

print("ok")
