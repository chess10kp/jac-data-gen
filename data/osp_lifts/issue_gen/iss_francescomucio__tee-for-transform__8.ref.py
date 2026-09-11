"""Reference harness: exercises every public function of iss_francescomucio__tee-for-transform__8."""
import importlib.util
import pathlib

_mod_path = pathlib.Path(__file__).parent / "iss_francescomucio__tee-for-transform__8.py"
_spec = importlib.util.spec_from_file_location("t4t_mod", _mod_path)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
build_model_graph = _mod.build_model_graph
parse_select = _mod.parse_select
resolve_selection = _mod.resolve_selection
select_models = _mod.select_models

# staging.customers -> marts.customers -> marts.dashboard; shared staging.dim feed.
deps, dependents = build_model_graph(
    ["staging.customers", "staging.dim", "staging.orders",
     "marts.customers", "marts.dashboard"],
    [
        ("marts.customers", "staging.customers"),
        ("marts.customers", "staging.orders"),
        ("marts.dashboard", "marts.customers"),
        ("marts.customers", "staging.dim"),
    ],
)

assert select_models(deps, dependents, "marts.customers+") == [
    "marts.customers", "staging.customers", "staging.dim", "staging.orders",
]
assert select_models(deps, dependents, "+marts.customers") == [
    "marts.customers", "marts.dashboard",
]
assert select_models(deps, dependents, "staging.dim+") == ["staging.dim"]
assert select_models(deps, dependents, "+staging.dim") == [
    "marts.customers", "staging.dim",
]

# Depth limiting: model+1 sees only immediate dependencies.
assert select_models(deps, dependents, "marts.customers+1") == [
    "marts.customers", "staging.customers", "staging.dim", "staging.orders",
]
assert select_models(deps, dependents, "marts.dashboard+1") == ["marts.customers", "marts.dashboard"]
assert select_models(deps, dependents, "+staging.customers2") == []

# Spec parsing.
assert parse_select("marts.a+") == ("marts.a", "upstream", 1)
assert parse_select("+b") == ("b", "downstream", 1)
assert parse_select("c") == ("c", "exact", 0)
assert parse_select("+d") == ("d", "downstream", 1)
try:
    parse_select("+d++")
    raise AssertionError("expected ValueError for mixed spec")
except ValueError:
    pass
assert parse_select("e+3") == ("e", "upstream", 3)

# Union across specs; unknown anchors contribute nothing.
assert resolve_selection(deps, dependents, ["marts.dashboard+", "+staging.orders"]) == [
    "marts.customers", "marts.dashboard", "staging.orders",
]
assert resolve_selection(deps, dependents, ["ghost+"]) == []
assert select_models(deps, dependents, "ghost") == []

print("tee-for-transform 8 ref OK")
