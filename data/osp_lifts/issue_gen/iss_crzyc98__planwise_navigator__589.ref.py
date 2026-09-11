"""Reference harness for iss_crzyc98__planwise_navigator__589."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_crzyc98__planwise_navigator__589.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
dag = _mod.load_mart_dag(
    [
        ("stg_nav_events", "staging", ["core"]),
        ("stg_policy_input", "staging", ["core"]),
        ("seed_policy_rules", "seed", ["demo"]),
        ("dim_plan", "dimension", ["core"]),
        ("fct_policy_metrics", "fact", ["core", "production"]),
        ("fct_policy_optimization", "fact", ["demo"]),
    ],
    [
        ("dim_plan", "stg_nav_events"),
        ("fct_policy_metrics", "dim_plan"),
        ("fct_policy_metrics", "stg_policy_input"),
        ("fct_policy_optimization", "seed_policy_rules"),
        ("fct_policy_optimization", "stg_policy_input"),
    ],
)

assert _mod.upstream_reach(dag, "fct_policy_metrics") == [
    "dim_plan",
    "stg_nav_events",
    "stg_policy_input",
]
assert _mod.upstream_reach(dag, "fct_policy_optimization") == [
    "seed_policy_rules",
    "stg_policy_input",
]
assert _mod.downstream_reach(dag, "stg_policy_input") == [
    "fct_policy_metrics",
    "fct_policy_optimization",
]
assert _mod.direct_referencers(dag, "stg_policy_input") == [
    "fct_policy_metrics",
    "fct_policy_optimization",
]
assert _mod.production_closure(dag, ["fct_policy_metrics"]) == [
    "dim_plan",
    "fct_policy_metrics",
    "stg_nav_events",
    "stg_policy_input",
]
assert _mod.orphan_facts(dag, ["fct_policy_metrics"]) == ["fct_policy_optimization"]

dia = _mod.load_mart_dag(
    [
        ("hub", "staging", []),
        ("arm_a", "staging", []),
        ("arm_b", "staging", []),
        ("join_mart", "fact", ["core"]),
    ],
    [
        ("join_mart", "arm_a"),
        ("join_mart", "arm_b"),
        ("arm_a", "hub"),
        ("arm_b", "hub"),
    ],
)
assert _mod.upstream_reach(dia, "join_mart") == ["arm_a", "arm_b", "hub"]

cyc = _mod.load_mart_dag(
    [("a", "staging", []), ("b", "staging", []), ("c", "staging", [])],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert _mod.upstream_reach(cyc, "a") == ["b", "c"]

assert _mod.upstream_reach(dag, "missing") == []
assert _mod.downstream_reach(dag, "missing") == []
assert _mod.direct_referencers(dag, "nope") == []
assert _mod.production_closure(dag, ["ghost"]) == []
assert _mod.orphan_facts(dag, ["ghost"]) == [
    "fct_policy_metrics",
    "fct_policy_optimization",
]
print("iss_crzyc98__planwise_navigator__589 ref OK")
