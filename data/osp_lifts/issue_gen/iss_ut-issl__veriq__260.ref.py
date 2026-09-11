"""Reference harness: exercises every public function of iss_ut-issl__veriq__260."""
import importlib

mod = importlib.import_module("iss_ut-issl__veriq__260")
load_tree = mod.load_tree
render_edges = mod.render_edges
dependencies_of = mod.dependencies_of
dependents_of = mod.dependents_of

tree = load_tree(
    ["check", "calc_a", "calc_b", "x"],
    [("check", "calc_a"), ("check", "calc_b"), ("calc_a", "x"), ("calc_b", "x")],
)
# Diamond: $.x must render under BOTH calcs (the issue's exact complaint).
assert render_edges(tree, "check") == [
    "calc_a>x",
    "calc_b>x",
    "check>calc_a",
    "check>calc_b",
]
assert dependencies_of(tree, "check") == ["calc_a", "calc_b", "check", "x"]
assert dependents_of(tree, "x") == ["calc_a", "calc_b", "check", "x"]

# Chain: no sharing, plain linear render.
chain = load_tree(["a", "b", "c"], [("a", "b"), ("b", "c")])
assert render_edges(chain, "a") == ["a>b", "b>c"]
assert dependencies_of(chain, "b") == ["b", "c"]

# Cycle: per-path policy terminates; each node rendered once along the loop.
cyc = load_tree(["p", "q"], [("p", "q"), ("q", "p")])
assert render_edges(cyc, "p") == ["p>q"]

# Unknown root renders nothing.
assert render_edges(tree, "ghost") == []

print("iss_ut-issl__veriq__260 ref OK")
