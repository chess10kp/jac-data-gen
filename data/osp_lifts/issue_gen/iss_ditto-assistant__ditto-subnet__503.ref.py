import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_ditto_503",
    Path(__file__).with_name("iss_ditto-assistant__ditto-subnet__503.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_query_graph(
    ["answer", "aggregate", "join_ab", "filter_a", "source_a", "source_b"],
    [
        ("source_a", "filter_a"),
        ("filter_a", "join_ab"),
        ("source_b", "join_ab"),
        ("join_ab", "aggregate"),
        ("aggregate", "answer"),
    ],
)
assert mod.reachable_steps(g, "answer") == [
    "aggregate", "answer", "filter_a", "join_ab", "source_a", "source_b"
]
order = mod.evaluation_order(g, "answer")
assert order[0] == "answer"
assert set(order) == set(mod.reachable_steps(g, "answer"))
print("ok")
