import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod",
    Path(__file__).with_name("iss_EffortlessMetrics__perl-lsp-swarm__8169.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

ps = mod.load_packages(
    ["root", "child", "grand"],
    {"root": None, "child": "root", "grand": "child"},
)
assert mod.package_ancestors(ps, "grand") == ["child", "root"]
assert mod.direct_parent(ps, "grand") == "child"
assert mod.package_ancestors(ps, "missing") == []
print("ok")
