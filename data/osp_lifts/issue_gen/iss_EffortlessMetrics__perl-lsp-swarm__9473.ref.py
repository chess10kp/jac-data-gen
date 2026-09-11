import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_9473",
    Path(__file__).with_name("iss_EffortlessMetrics__perl-lsp-swarm__9473.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_calls(
    ["c1", "c2", "c3"],
    {
        "c1": ["obj:Pkg::Foo"],
        "c2": ["obj:Pkg::A", "obj:Pkg::B"],
        "c3": ["void"],
    },
)
assert mod.direct_receiver(store, "c1") == "Pkg::Foo"
assert mod.receiver_outcome(store, "c1") == "exact"
assert mod.receiver_outcome(store, "c2") == "qualified"
assert mod.receiver_outcome(store, "c3") == "unavailable"
assert mod.propagate_receiver(store, "c1") == "Pkg::Foo"
assert mod.propagate_receiver(store, "c2") is None
print("ok")
