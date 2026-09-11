import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_D22977__gpt-browser-bridge__25",
    Path(__file__).with_name("iss_D22977__gpt-browser-bridge__25.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)
st = mod.load_processes([
    (100, 50, "GBB-REVIEWER pwsh"),
    (50, 10, "services.exe"),
    (10, None, "init"),
])
assert mod.ancestor_chain(st, 100) == [100, 50, 10]
assert mod.forbidden_ancestors(st, 100, ["ORCA", "GBBWorker"]) == []
st2 = mod.load_processes([
    (7, 6, "worker ORCA probe"),
    (6, 5, "GBBWorker service"),
    (5, None, "init"),
])
assert mod.forbidden_ancestors(st2, 7, ["ORCA", "GBBWorker"]) == [7, 6]
st3 = mod.load_processes([(1, 2, "a"), (2, 1, "b")])
assert mod.ancestor_chain(st3, 1) == [1, 2]
assert mod.ancestor_chain(st, 999) == []
print("ok")
