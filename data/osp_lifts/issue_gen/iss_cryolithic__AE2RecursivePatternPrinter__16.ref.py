import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_ae2_16",
    Path(__file__).with_name("iss_cryolithic__AE2RecursivePatternPrinter__16.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

net = mod.load_network(
    {
        "gear": ["iron", "stick"],
        "iron": ["ore"],
        "stick": ["wood"],
    },
    existing_patterns=["wood"],
)
assert mod.analyze_pattern(net, ["gear"]) == ["ore", "iron", "stick", "gear"]
assert mod.missing_recipes(net, ["gear", "mystery"]) == ["mystery"]

net2 = mod.load_network({"a": ["b"], "b": ["a"]})
assert sorted(mod.analyze_pattern(net2, ["a"])) == ["a", "b"]
print("ok")
