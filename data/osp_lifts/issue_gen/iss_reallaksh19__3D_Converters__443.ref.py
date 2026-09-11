import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_reallaksh19__3D_Converters__443",
    Path(__file__).with_name("iss_reallaksh19__3D_Converters__443.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

FIT = mod.load_calc_graph(
    ["topology", "operating", "enrichment", "screening", "LOF"],
    [
        ("topology", "screening"),
        ("operating", "screening"),
        ("enrichment", "screening"),
        ("screening", "LOF"),
    ],
)
assert mod.prerequisites(FIT, "LOF") == [
    "LOF", "enrichment", "operating", "screening", "topology",
]
assert mod.ready_calcs(FIT, []) == ["enrichment", "operating", "topology"]
assert mod.ready_calcs(FIT, ["topology", "operating", "enrichment"]) == ["screening"]
assert mod.prerequisites(FIT, "missing") == []
print("ok")
