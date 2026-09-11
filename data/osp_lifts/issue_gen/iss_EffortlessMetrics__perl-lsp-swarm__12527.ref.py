import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_EffortlessMetrics__perl-lsp-swarm__12527",
    Path(__file__).with_suffix(".py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

MODULES = ["Main.pm", "Base.pm", "Util.pm", "Cfg.pm"]
EDGES = [
    ("Main.pm", "Base.pm"),
    ("Main.pm", "Util.pm"),
    ("Util.pm", "Cfg.pm"),
]
CYCLE = [("A.pm", "B.pm"), ("B.pm", "C.pm"), ("C.pm", "A.pm")]

g = mod.load_project(MODULES, EDGES)
assert mod.module_closure(g, "Main.pm") == ["Base.pm", "Cfg.pm", "Main.pm", "Util.pm"]
assert mod.compile_waves(g) == [["Base.pm", "Cfg.pm"], ["Util.pm"], ["Main.pm"]]
assert mod.has_import_cycle(g) is False

cg = mod.load_project(["A.pm", "B.pm", "C.pm"], CYCLE)
assert mod.has_import_cycle(cg) is True
assert mod.compile_waves(cg) is None
assert mod.module_closure(cg, "missing.pm") == []

print("ok")
