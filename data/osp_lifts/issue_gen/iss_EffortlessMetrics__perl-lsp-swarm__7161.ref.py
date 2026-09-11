import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod",
    Path(__file__).with_name("iss_EffortlessMetrics__perl-lsp-swarm__7161.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

ps = mod.load_patterns(["main", "sub", "leaf"], [("main", "sub"), ("sub", "leaf")])
assert mod.call_reachable(ps, "main", 2) == ["leaf", "main", "sub"]
assert mod.budget_exhausted(ps, "main", 0) is True
assert mod.mutual_cycle_detected(mod.load_patterns(["a", "b"], [("a", "b"), ("b", "a")]), "a") is True
print("ok")
