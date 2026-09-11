"""Reference harness: exercises every public function of iss_paulnsorensen__milknado__292."""
from iss_paulnsorensen__milknado__292 import HarvestSummary, build_tree, harvest

nodes = [
    ("goal", "  quarterly rollup  "),
    ("eng", "ship log"),
    ("web", "   "),          # whitespace-only: omitted
    ("infra", "deploy notes"),
]
edges = [("goal", "eng"), ("goal", "web"), ("eng", "infra")]
adj, dep = build_tree(nodes, edges)

res = harvest(adj, dep, "goal")
assert res == HarvestSummary(["deploy notes", "quarterly rollup", "ship log"], False, False)
assert res.summaries == ["deploy notes", "quarterly rollup", "ship log"]

# Leaf view.
assert harvest(adj, dep, "infra").summaries == ["deploy notes"]
# Blank-only subtree yields an empty summary.
assert harvest(adj, dep, "web").summaries == []

# Unknown goals project nothing.
empty = harvest(adj, dep, "ghost")
assert empty.summaries == [] and not empty.truncated_results

# Shared child is counted once.
shared_nodes = [("a", "alpha"), ("b", "beta"), ("shared", "gamma")]
shared_edges = [("a", "shared"), ("b", "shared")]
adj2, dep2 = build_tree(shared_nodes, shared_edges)
assert harvest(adj2, dep2, "a").summaries == ["alpha", "gamma"]

# Cyclic topology terminates without duplicates.
cyc_nodes = [("x", "ex"), ("y", "why")]
cyc_edges = [("x", "y"), ("y", "x")]
adj3, dep3 = build_tree(cyc_nodes, cyc_edges)
assert harvest(adj3, dep3, "x").summaries == ["ex", "why"]

# Size cap fires and reports; smaller budget truncates more.
big_nodes = [(str(i), "t" * 8 + "%02d" % i) for i in range(20)]
big_edges = [("0", str(i)) for i in range(1, 20)]
big_adj, big_dep = build_tree(big_nodes, big_edges)
small = harvest(big_adj, big_dep, "0", max_total=25)
assert small.truncated_size
assert sum(len(s) for s in small.summaries) + len(small.summaries) - 1 <= 25
roomy = harvest(big_adj, big_dep, "0", max_total=4096)
assert not roomy.truncated_size and not roomy.truncated_results
assert len(roomy.summaries) == 20

print("milknado 292 ref OK")
