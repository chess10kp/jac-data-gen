import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_StellarChainproof__StellarChainproofs__66",
    Path(__file__).with_name("iss_StellarChainproof__StellarChainproofs__66.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_call_graph(
    [
        ("A.deposit", "A"),
        ("B.withdraw", "B"),
        ("A.callback", "A"),
        ("C.route", "C"),
    ],
    [
        ("A.deposit", "B.withdraw"),
        ("B.withdraw", "C.route"),
        ("C.route", "A.callback"),
    ],
    ["A.deposit", "A.callback"],
)
hits = mod.reentrant_chains(g, "A.deposit", 3)
assert "A.callback" in hits
assert mod.cross_contract_hops(g, "A.deposit", 3) == [
    "A.callback",
    "B.withdraw",
    "C.route",
]
assert mod.is_guarded_chain(g, ["A.deposit", "B.withdraw"], {"A.deposit"}) is False
assert mod.contracts_in_chain(g, ["A.deposit", "B.withdraw", "A.callback"]) == [
    "A",
    "B",
]
print("ok")
