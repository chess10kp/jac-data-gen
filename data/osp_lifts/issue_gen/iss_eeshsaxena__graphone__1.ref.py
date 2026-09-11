import importlib.util
from pathlib import Path

p = Path(__file__).with_suffix(".py")
spec = importlib.util.spec_from_file_location("graphone1", p)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

load_graph = mod.load_graph
graph_endpoint = mod.graph_endpoint
has_investment_cycle = mod.has_investment_cycle
investors_of = mod.investors_of

CHAIN = load_graph(
    [("a", "Alpha"), ("b", "Beta"), ("c", "Gamma")],
    [("a", "b"), ("b", "c")],
)
assert graph_endpoint(CHAIN, "a") == ["a", "b", "c"]
assert has_investment_cycle(CHAIN, "a") is False
assert investors_of(CHAIN, "c") == ["b"]

CYCLE = load_graph(
    [("a", "A"), ("b", "B"), ("c", "C")],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert graph_endpoint(CYCLE, "a") == ["a", "b", "c"]
assert has_investment_cycle(CYCLE, "a") is True

DIAMOND = load_graph(
    [("top", "T"), ("l", "L"), ("r", "R"), ("base", "B")],
    [("top", "l"), ("top", "r"), ("l", "base"), ("r", "base")],
)
assert graph_endpoint(DIAMOND, "top") == ["base", "l", "r", "top"]

assert graph_endpoint(CHAIN, "missing") == []
assert has_investment_cycle(CHAIN, "missing") is False
assert investors_of(CHAIN, "missing") == []
