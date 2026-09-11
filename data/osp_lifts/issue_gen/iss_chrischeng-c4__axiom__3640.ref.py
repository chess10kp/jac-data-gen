"""Reference harness for iss_chrischeng-c4__axiom__3640."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_chrischeng-c4__axiom__3640.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
sites = [
    "ov_prod",
    "as_int_bridge",
    "helper_table",
    "table_lookup",
    "threshold_gate",
    "first_live",
    "private_slot",
    "uid_ctrl",
]
edges = [
    ("ov_prod", "as_int_bridge"),
    ("ov_prod", "helper_table"),
    ("as_int_bridge", "table_lookup"),
    ("helper_table", "table_lookup"),
    ("as_int_bridge", "threshold_gate"),
    ("threshold_gate", "first_live"),
]
adj = _mod.build_flow_graph(sites, edges)

site_kinds = {
    "ov_prod": "producer",
    "as_int_bridge": "classifier",
    "helper_table": "registry",
    "table_lookup": "consumer",
    "threshold_gate": "classifier",
    "first_live": "consumer",
    "private_slot": "private_metadata",
    "uid_ctrl": "python_numeric",
}

assert _mod.downstream_reach(
    adj,
    ["ov_prod"],
    site_kinds=site_kinds,
    target_kinds=frozenset({"consumer", "registry"}),
) == ["first_live", "helper_table", "table_lookup"]
assert _mod.downstream_reach(
    adj,
    ["as_int_bridge"],
    site_kinds=site_kinds,
    target_kinds=frozenset({"consumer"}),
) == ["first_live", "table_lookup"]
assert _mod.downstream_reach(adj, ["ghost"]) == []

parent_of = {
    "as_int_bridge": "ov_prod",
    "table_lookup": "as_int_bridge",
    "threshold_gate": "as_int_bridge",
    "first_live": "threshold_gate",
}
assert _mod.parent_route_chain(parent_of, "first_live") == [
    "threshold_gate",
    "as_int_bridge",
    "ov_prod",
]
assert _mod.parent_route_chain(parent_of, "ov_prod") == []
assert _mod.parent_route_chain(parent_of, "ghost") == []
assert _mod.parent_route_chain({"a": "b", "b": "c", "c": "a"}, "a") == ["b", "c"]

rows = {
    "ov_prod": {
        "kind": "producer",
        "disposition": "legacy_debt",
        "family": "OsSurrogateFd",
        "parent_route": "ov_family",
    },
    "uid_ctrl": {
        "kind": "python_numeric",
        "disposition": "python_numeric",
    },
}
ledger = _mod.load_ledger(["ov_prod", "uid_ctrl", "missing_site"], rows)
assert ledger["ov_prod"]["family"] == "OsSurrogateFd"
assert ledger["uid_ctrl"]["disposition"] == "python_numeric"
assert ledger["missing_site"]["disposition"] == "needs_classification"

clean_ledger = {
    "ov_prod": {
        "kind": "producer",
        "disposition": "legacy_debt",
        "parent_route": "ov_family",
    },
    "as_int_bridge": {
        "kind": "classifier",
        "disposition": "legacy_debt",
        "parent_route": "ov_prod",
    },
    "helper_table": {"kind": "registry", "disposition": "typed_token"},
    "table_lookup": {"kind": "consumer", "disposition": "typed_token"},
    "threshold_gate": {
        "kind": "classifier",
        "disposition": "typed_token",
        "parent_route": "thr",
    },
    "first_live": {"kind": "consumer", "disposition": "typed_token"},
    "private_slot": {"kind": "private_metadata", "disposition": "private_only"},
    "uid_ctrl": {"kind": "python_numeric", "disposition": "python_numeric"},
}
assert _mod.audit_inventory(
    adj,
    sites,
    clean_ledger,
    site_kinds,
    covered_files=frozenset(["opaque_value_boundary.py"]),
    source_files=["opaque_value_boundary.py"],
) == []

bad_producer = dict(clean_ledger)
bad_producer["ov_prod"] = {
    **clean_ledger["ov_prod"],
    "disposition": "python_numeric",
}
assert _mod.audit_inventory(adj, sites, bad_producer, site_kinds) == [
    "producer_misclassified_numeric:ov_prod",
]

unclassified = dict(clean_ledger)
unclassified["helper_table"] = {"disposition": "needs_classification"}
assert _mod.audit_inventory(adj, sites, unclassified, site_kinds) == [
    "unclassified:helper_table",
]

no_route = dict(clean_ledger)
no_route["as_int_bridge"] = {
    k: v for k, v in clean_ledger["as_int_bridge"].items() if k != "parent_route"
}
assert _mod.audit_inventory(adj, sites, no_route, site_kinds) == [
    "as_int_without_route:as_int_bridge",
]

reified = dict(clean_ledger)
reified["private_slot"] = {**clean_ledger["private_slot"], "reified": True}
assert _mod.audit_inventory(adj, sites, reified, site_kinds) == [
    "private_reified:private_slot",
]

assert _mod.audit_inventory(
    adj,
    sites,
    clean_ledger,
    site_kinds,
    source_files=["opaque_value_boundary.py", "new_producer.rs"],
    covered_files=frozenset(["opaque_value_boundary.py"]),
) == ["uncovered_file:new_producer.rs"]

assert _mod.audit_inventory(
    adj,
    sites,
    clean_ledger,
    site_kinds,
    stale=frozenset(["table_lookup"]),
) == ["stale_row:table_lookup"]

assert _mod.audit_inventory(
    adj,
    sites,
    clean_ledger,
    site_kinds,
    mode="typed_only",
) == ["legacy_debt_blocks_typed_token"]

cyc_adj = _mod.build_flow_graph(
    ["a", "b", "c"],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert _mod.downstream_reach(cyc_adj, ["a"]) == ["b", "c"]
print("iss_chrischeng-c4__axiom__3640 ref OK")
