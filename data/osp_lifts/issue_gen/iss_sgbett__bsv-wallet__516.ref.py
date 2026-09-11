import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_bsv_516",
    Path(__file__).with_name("iss_sgbett__bsv-wallet__516.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

ts = mod.load_tx_graph(["t0", "t1", "t2", "t3"], [("t1", "t0"), ("t2", "t1"), ("t3", "t2")])
assert mod.unproven_ancestors(ts, "t3") == ["t0", "t1", "t2"]
mod.mark_verified(ts, "t0")
assert mod.unproven_ancestors(ts, "t3") == ["t1", "t2"]
assert mod.cache_hits(ts, ["t0", "t1", "t2"]) == ["t0"]
print("ok")
