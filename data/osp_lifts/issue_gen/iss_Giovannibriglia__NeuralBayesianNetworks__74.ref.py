"""Reference harness: exercises every public function of iss_Giovannibriglia__NeuralBayesianNetworks__74."""
import importlib.util
import pathlib

_mod_path = pathlib.Path(__file__).parent / "iss_Giovannibriglia__NeuralBayesianNetworks__74.py"
_spec = importlib.util.spec_from_file_location("nbn_mod", _mod_path)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
allocate_queries = _mod.allocate_queries
build_dag = _mod.build_dag
hub_nodes = _mod.hub_nodes
markov_blanket = _mod.markov_blanket
role_profile = _mod.role_profile
terminal_nodes = _mod.terminal_nodes

# Sprinkler-style DAG plus a hub node "cloud" with two children.
dag = build_dag(
    ["cloud", "rain", "sprinkler", "grass_wet", "puddle"],
    [
        ("cloud", "rain"), ("cloud", "sprinkler"),
        ("rain", "grass_wet"), ("sprinkler", "grass_wet"),
        ("grass_wet", "puddle"),
    ],
)

assert markov_blanket(dag, "grass_wet") == ["puddle", "rain", "sprinkler"]
assert markov_blanket(dag, "cloud") == ["rain", "sprinkler"]
assert markov_blanket(dag, "ghost") == []

profile = role_profile(dag)
by_node = {node: (mb, dc) for node, mb, dc in profile}
assert by_node["cloud"] == (2, 4)
assert by_node["grass_wet"] == (3, 1)
assert by_node["puddle"] == (1, 0)

# Hub selection: grass_wet has the largest blanket; rain beats sprinkler by name.
assert hub_nodes(dag, 2) == ["grass_wet", "rain"]
# Terminals: puddle has no descendants, then grass_wet, then the (2, name) ties.
assert terminal_nodes(dag, 3) == ["puddle", "grass_wet", "rain"]

# Deterministic allocation split.
assert allocate_queries(100) == (30, 25, 45)
assert allocate_queries(10) == (3, 2, 5)
assert allocate_queries(0) == (0, 0, 0)

# Disconnected components and cycles still profile without hanging.
weird = build_dag(["a", "b", "c"], [("a", "b"), ("b", "a")])
assert terminal_nodes(weird, 3) == ["c", "a", "b"]
assert markov_blanket(weird, "a") == ["b"]

print("NeuralBayesianNetworks 74 ref OK")
