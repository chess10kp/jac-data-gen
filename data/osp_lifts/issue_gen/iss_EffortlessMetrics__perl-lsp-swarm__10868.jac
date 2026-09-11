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
