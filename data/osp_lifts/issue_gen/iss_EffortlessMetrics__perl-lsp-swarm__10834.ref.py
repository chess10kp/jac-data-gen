"""Reference harness for EffortlessMetrics/perl-lsp-swarm#10834."""

import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_EffortlessMetrics__perl-lsp-swarm__10834",
    Path(__file__).with_suffix(".py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

load_cfg = mod.load_cfg
propagate_receivers = mod.propagate_receivers
receivers_at = mod.receivers_at

BIND = "main::$x"
POINTS = ["entry", "after_foo_init", "call_foo", "after_bar_assign", "call_bar"]
EDGES = [
    ("entry", "after_foo_init"),
    ("after_foo_init", "call_foo"),
    ("call_foo", "after_bar_assign"),
    ("after_bar_assign", "call_bar"),
]
ASSIGNS = [
    ("after_foo_init", BIND, "Foo"),
    ("after_bar_assign", BIND, "Bar"),
]

g = load_cfg(POINTS, EDGES, ASSIGNS, "entry")
snaps = propagate_receivers(g)
assert receivers_at(g, "call_foo", BIND) == "Foo"
assert receivers_at(g, "call_bar", BIND) == "Bar"
assert snaps["call_foo"][BIND] == "Foo"
assert snaps["call_bar"][BIND] == "Bar"

# unknown point tolerance
assert receivers_at(g, "missing", BIND) is None

# unknown RHS preserves prior receiver
g2 = load_cfg(
    ["entry", "keep", "query"],
    [("entry", "keep"), ("keep", "query")],
    [("keep", BIND, "Foo"), ("query", BIND, "")],
    "entry",
)
assert receivers_at(g2, "query", BIND) == "Foo"

# distinct binding identities (sigil + scope shadowing)
g3 = load_cfg(
    ["entry", "inner", "exit"],
    [("entry", "inner"), ("inner", "exit")],
    [
        ("entry", "main::$x", "Foo"),
        ("entry", "main::@x", "Arr"),
        ("inner", "block::$x", "Bar"),
    ],
    "entry",
)
propagate_receivers(g3)
assert receivers_at(g3, "exit", "main::$x") == "Foo"
assert receivers_at(g3, "exit", "main::@x") == "Arr"
assert receivers_at(g3, "exit", "block::$x") == "Bar"

print("ok")
