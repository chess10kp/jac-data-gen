"""Reference harness for corygadcock/network-dashboard#7."""

import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_corygadcock__network-dashboard__7",
    Path(__file__).with_suffix(".py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_topology(
    ["host", "switch", "router", "gw"],
    [("host", "switch"), ("switch", "router"), ("router", "gw")],
)
assert mod.trace_to_gateway(store, "host", "gw") == (
    ["host", "switch", "router", "gw"],
    None,
)

partial = mod.load_topology(
    ["a", "b", "c"],
    [("a", "b"), ("b", "c")],
)
assert mod.trace_to_gateway(partial, "a", "gw") == (
    ["a", "b", "c"],
    "missing_documentation",
)

assert mod.trace_to_gateway(store, "nope", "gw") == ([], "unknown_start")

diamond = mod.load_topology(
    ["s", "a", "b", "t"],
    [("s", "a"), ("s", "b"), ("a", "t"), ("b", "t")],
)
assert mod.trace_to_gateway(diamond, "s", "t") == (["s", "a", "t"], None)

self_gw = mod.load_topology(["gw"], [])
assert mod.trace_to_gateway(self_gw, "gw", "gw") == (["gw"], None)

cycle = mod.load_topology(
    ["a", "b", "c", "gw"],
    [("a", "b"), ("b", "c"), ("c", "a"), ("c", "gw")],
)
assert mod.trace_to_gateway(cycle, "a", "gw") == (["a", "b", "c", "gw"], None)

print("ok")
