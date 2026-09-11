"""Reference harness for iss_WillSmithTE__intlayer__1."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_WillSmithTE__intlayer__1.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
g = _mod.EntrypointGraph()
g.register("intlayer/types", "runtime", 8)
g.register("intlayer/runtime", "runtime", 12)
g.register("intlayer/server", "server", 40)
g.register("intlayer/dev", "dev", 600)
g.register("intlayer/cli", "cli", 300)
g.register("next-intlayer/server", "server", 200)
g.register("next-intlayer/dev", "dev", 900)
g.link("intlayer/types", "intlayer/runtime")
g.link("intlayer/runtime", "intlayer/server")
g.link("intlayer/server", "intlayer/dev")
g.link("next-intlayer/server", "next-intlayer/dev")
g.link("next-intlayer/server", "intlayer/server")
assert g.reachable_modules("intlayer/types") == [
    "intlayer/dev",
    "intlayer/runtime",
    "intlayer/server",
    "intlayer/types",
]
assert g.reachable_weight_kb("intlayer/types") == 8 + 12 + 40 + 600
assert g.dev_leakage("intlayer/types") == ["intlayer/dev"]
assert g.dev_leakage("intlayer/runtime") == ["intlayer/dev"]
report = g.separation_report(["intlayer/types", "next-intlayer/server"])
assert report["intlayer/types"][0] == 660
assert report["next-intlayer/server"][1] == ["intlayer/dev", "next-intlayer/dev"]
isolated = g.would_isolate(
    "intlayer/types",
    [("intlayer/server", "intlayer/dev"), ("intlayer/runtime", "intlayer/server")],
)
assert isolated == 8 + 12
try:
    g.register("bad", "webpack", 1)
    assert False, "expected invalid layer rejection"
except _mod.IntlayerGraphError:
    pass
try:
    g.link("missing", "intlayer/runtime")
    assert False, "expected unknown entry rejection"
except _mod.IntlayerGraphError:
    pass
try:
    g.reachable_modules("ghost")
    assert False, "expected unknown root rejection"
except _mod.IntlayerGraphError:
    pass
print("iss_WillSmithTE__intlayer__1 ref OK")
