"""Synthetic before-code for EffortlessMetrics/perl-lsp-swarm#10868.

Project exact owner-to-target liveness edges from canonical reference
occurrences using idiomatic OSP graph machinery.
"""

glob BLOCKED_SOURCES = ["ref-source", "name-derived", "compat-projection"];
glob ADMITTED_KINDS = [
    "direct_call",
    "qualified_call",
    "static_method",
    "coderef_capture",
    "import_alias",
    "typeglob_alias",
];

node ExecUnit {
    has exec_id: str;
}

edge Liveness: ExecUnit --> ExecUnit {}

walker LiveReach {
    has claimed: dict[str, bool] = {};
    has live: set[str] = set();

    can step with ExecUnit entry {
        self.live.add(here.exec_id);
        if here.exec_id in self.claimed { skip; }
        self.claimed[here.exec_id] = True;
        visit [->:Liveness:->][?:ExecUnit];
    }
}

def is_blocked_source(source_kind: str) -> bool {
    return source_kind in BLOCKED_SOURCES;
}

def _exact_projection_allowed(occ: dict, facts: dict[str, dict]) -> bool {
    owner = facts.get(occ.get("owner_id", ""), None);
    target = facts.get(occ.get("target_id", ""), None);
    if owner is None or target is None { return False; }
    gen = occ.get("generation", 0);
    if gen < owner.get("generation", 0) or gen < target.get("generation", 0) {
        return False;
    }
    occ_root = occ.get("root_id", None);
    return occ_root == owner.get("root_id", None) and occ_root == target.get("root_id", None);
}

def project_exact_edges(
    occurrences: list[dict],
    facts: dict[str, dict],
) -> list[dict] {
    projected: list[dict] = [];
    for occ in occurrences {
        if is_blocked_source(occ.get("source_kind", "")) { continue; }
        kind = occ.get("kind", "");
        if not (kind in ADMITTED_KINDS) { continue; }
        if not _exact_projection_allowed(occ, facts) { continue; }
        owner = facts[occ["owner_id"]];
        target = facts[occ["target_id"]];
        projected.append({
            "owner": owner["exec_id"],
            "target": target["exec_id"],
            "kind": kind,
            "occurrence_id": occ["occurrence_id"],
            "root": owner["root_id"],
            "generation": occ["generation"],
            "source_kind": occ.get("source_kind", "canonical"),
        });
    }
    return projected;
}

def canonical_edge_set(edges: list[dict]) -> list[tuple] {
    keys: list[tuple] = [];
    for edge in edges {
        keys.append((
            edge["owner"],
            edge["target"],
            edge["kind"],
            edge["occurrence_id"],
            edge["root"],
            edge["generation"],
            edge["source_kind"],
        ));
    }
    return sorted(keys);
}

def liveness_closure(root_owner: str, edges: list[dict]) -> set[str] {
    nodes: dict[str, ExecUnit] = {};
    for edge in edges {
        owner_key = edge["owner"];
        target_key = edge["target"];
        if not (owner_key in nodes) {
            owner_nd = ExecUnit(exec_id=owner_key);
            root ++> owner_nd;
            nodes[owner_key] = owner_nd;
        }
        if not (target_key in nodes) {
            target_nd = ExecUnit(exec_id=target_key);
            root ++> target_nd;
            nodes[target_key] = target_nd;
        }
        nodes[owner_key] +>:Liveness:+> nodes[target_key];
    }
    live_out: set[str] = set();
    live_out.add(root_owner);
    if not (root_owner in nodes) { return live_out; }
    seed: set[str] = set();
    seed.add(root_owner);
    w = nodes[root_owner] spawn LiveReach(claimed={}, live=seed);
    return w.live;
}

test "liveness diamond revisit converges" {
    edges = [
        {"owner": "A", "target": "B"},
        {"owner": "A", "target": "C"},
        {"owner": "B", "target": "D"},
        {"owner": "C", "target": "D"},
    ];
    live = liveness_closure("A", edges);
    assert sorted(list(live)) == ["A", "B", "C", "D"];
}

test "liveness diamond adversarial revisit" {
    edges = [
        {"owner": "C", "target": "D"},
        {"owner": "B", "target": "D"},
        {"owner": "A", "target": "B"},
        {"owner": "A", "target": "C"},
    ];
    live = liveness_closure("A", edges);
    assert sorted(list(live)) == ["A", "B", "C", "D"];
}

test "liveness cycle claim map skip" {
    edges = [
        {"owner": "A", "target": "B"},
        {"owner": "B", "target": "C"},
        {"owner": "C", "target": "A"},
        {"owner": "A", "target": "D"},
    ];
    live = liveness_closure("A", edges);
    assert sorted(list(live)) == ["A", "B", "C", "D"];
}

test "liveness cycle order independent" {
    edges_a = [
        {"owner": "A", "target": "B"},
        {"owner": "B", "target": "A"},
    ];
    edges_b = [
        {"owner": "B", "target": "A"},
        {"owner": "A", "target": "B"},
    ];
    live_a = liveness_closure("A", edges_a);
    live_b = liveness_closure("A", edges_b);
    assert sorted(list(live_a)) == ["A", "B"];
    assert live_a == live_b;
}

test "liveness unknown root tolerated" {
    live = liveness_closure("ghost", [{"owner": "A", "target": "B"}]);
    assert sorted(list(live)) == ["ghost"];
}

test "project skips missing fact ids" {
    occs = [{
        "occurrence_id": "o1",
        "owner_id": "gone",
        "target_id": "t1",
        "kind": "direct_call",
        "generation": 1,
        "root_id": "r1",
    }];
    facts = {
        "t1": {"exec_id": "exec-t1", "root_id": "r1", "generation": 0},
    };
    assert project_exact_edges(occs, facts) == [];
}

test "project blocks ref source and generation mismatch" {
    occs = [
        {
            "occurrence_id": "o-blocked",
            "owner_id": "o1",
            "target_id": "t1",
            "kind": "direct_call",
            "generation": 2,
            "root_id": "r1",
            "source_kind": "ref-source",
        },
        {
            "occurrence_id": "o-stale",
            "owner_id": "o1",
            "target_id": "t1",
            "kind": "direct_call",
            "generation": 0,
            "root_id": "r1",
        },
        {
            "occurrence_id": "o-ok",
            "owner_id": "o1",
            "target_id": "t1",
            "kind": "direct_call",
            "generation": 2,
            "root_id": "r1",
        },
    ];
    facts = {
        "o1": {"exec_id": "exec-o1", "root_id": "r1", "generation": 1},
        "t1": {"exec_id": "exec-t1", "root_id": "r1", "generation": 1},
    };
    projected = project_exact_edges(occs, facts);
    assert len(projected) == 1;
    assert projected[0]["occurrence_id"] == "o-ok";
    assert projected[0]["owner"] == "exec-o1";
    assert projected[0]["target"] == "exec-t1";
}

test "canonical edge set order independent" {
    e1 = {
        "owner": "a",
        "target": "b",
        "kind": "direct_call",
        "occurrence_id": "o2",
        "root": "r",
        "generation": 1,
        "source_kind": "canonical",
    };
    e2 = {
        "owner": "z",
        "target": "y",
        "kind": "import_alias",
        "occurrence_id": "o1",
        "root": "r",
        "generation": 0,
        "source_kind": "canonical",
    };
    got_a = canonical_edge_set([e1, e2]);
    got_b = canonical_edge_set([e2, e1]);
    assert got_a == got_b;
    assert got_a == [
        ("a", "b", "direct_call", "o2", "r", 1, "canonical"),
        ("z", "y", "import_alias", "o1", "r", 0, "canonical"),
    ];
}
