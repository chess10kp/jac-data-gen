"""TalonT-Org/AutoSkillit#3951 — planner post-compile BEM integration (pre-lift)."""

node Plan {
    has plan_id: str;
}

edge DependsOn {}

obj PlanGraph {
    has plans: dict[str, Plan] = {};
}

walker KahnWave {
    has done: dict[str, bool] = {};
    has wave: list[str] = [];

    can begin with Root entry {
        visit [-->][?:Plan];
    }

    can scan with Plan entry {
        if here.plan_id in self.done { skip; }
        ups = [here ->:DependsOn:->][?:Plan];
        for up in ups {
            if not self.done.get(up.plan_id, False) { skip; }
        }
        self.wave.append(here.plan_id);
    }

    can finish with Root exit {
        report sorted(self.wave);
    }
}

def _depends_on(row: dict[str, object]) -> list[str] {
    if "depends_on" not in row { return []; }
    raw = row["depends_on"] as list;
    out: list[str] = [];
    for dep in raw { out.append(str(dep)); }
    return out;
}

def _graph_from_issues(issues: list[dict[str, object]]) -> PlanGraph {
    g = PlanGraph();
    for row in issues {
        pid = str(row["plan_id"]);
        nd = Plan(plan_id=pid);
        root ++> nd;
        g.plans[pid] = nd;
    }
    for row in issues {
        pid = str(row["plan_id"]);
        dn = g.plans[pid];
        for dep in _depends_on(row) {
            up = g.plans.get(dep, None);
            if up is not None { dn +>:DependsOn:+> up; }
        }
    }
    return g;
}

def _graph_from_dep_adj(dep_adj: dict[str, list[str]]) -> PlanGraph {
    g = PlanGraph();
    for pid in dep_adj {
        nd = Plan(plan_id=pid);
        root ++> nd;
        g.plans[pid] = nd;
    }
    for (pid, deps) in dep_adj.items() {
        dn = g.plans[pid];
        for dep in deps {
            up = g.plans.get(dep, None);
            if up is not None { dn +>:DependsOn:+> up; }
        }
    }
    return g;
}

def build_dep_adjacency(issues: list[dict]) -> dict[str, list[str]] {
    g = _graph_from_issues(issues);
    adj: dict[str, list[str]] = {};
    for row in issues {
        pid = str(row["plan_id"]);
        deps: list[str] = [];
        for dep in _depends_on(row) {
            if dep in g.plans { deps.append(dep); }
        }
        adj[pid] = deps;
    }
    return adj;
}

def build_successor_adjacency(dep_adj: dict[str, list[str]]) -> dict[str, list[str]] {
    g = _graph_from_dep_adj(dep_adj);
    succ: dict[str, list[str]] = {};
    for pid in g.plans {
        nd = g.plans[pid];
        nxt: list[str] = [];
        for dn in [nd <-:DependsOn:<-][?:Plan] {
            nxt.append(dn.plan_id);
        }
        succ[pid] = sorted(nxt);
    }
    return succ;
}

def kahn_parallel_groups(dep_adj: dict[str, list[str]]) -> list[list[str]] {
    g = _graph_from_dep_adj(dep_adj);
    groups: list[list[str]] = [];
    done: dict[str, bool] = {};
    total = len(g.plans);
    while len(done) < total {
        w = root spawn KahnWave(done=done);
        raw_wave = w.reports[0] if w.reports else [];
        # dedup and filter to current graph (root holds historic Plans)
        seen_w: dict[str, bool] = {};
        wave: list[str] = [];
        for pid in raw_wave {
            if pid in g.plans and pid not in seen_w {
                seen_w[pid] = True;
                wave.append(pid);
            }
        }
        wave = sorted(wave);
        if len(wave) == 0 { break; }
        groups.append(wave);
        for pid in wave { done[pid] = True; }
    }
    return groups;
}

def flatten_merge_order(groups: list[list[str]]) -> list[str] {
    order: list[str] = [];
    for group in groups {
        for pid in group { order.append(pid); }
    }
    return order;
}

def load_bem_groups(execution_map: dict) -> list[list[str]] {
    raw: list = [];
    if "groups" in execution_map {
        raw = execution_map["groups"] as list;
    }
    out: list[list[str]] = [];
    for grp in raw {
        row: list[str] = [];
        for item in grp as list { row.append(str(item)); }
        out.append(sorted(row));
    }
    return out;
}

def infer_group_types(groups: list[list[str]]) -> list[str] {
    out: list[str] = [];
    for grp in groups {
        out.append("parallel" if len(grp) > 1 else "sequential");
    }
    return out;
}

def assign_dispatch_labels(merge_order: list[str]) -> dict[str, str] {
    labels: dict[str, str] = {};
    idx = 1;
    for pid in merge_order {
        labels[pid] = f"D-{idx:02d}";
        idx += 1;
    }
    return labels;
}

def rename_issue_title(plan_id: str, title: str, dispatch_label: str) -> str {
    return f"[{dispatch_label}] {plan_id}: {title}";
}

def _peer_order_in_group(
    plan_id: str,
    group: list[str],
    merge_order: list[str],
) -> list[str] {
    _ = plan_id;
    peers: list[str] = [];
    for p in merge_order {
        if p in group { peers.append(p); }
    }
    return peers;
}

def format_execution_context(
    plan_id: str,
    groups: list[list[str]],
    merge_order: list[str],
    group_types: list[str],
    plan_to_issue: dict[str, int],
    plan_to_title: dict[str, str],
    deferred: list[str] | None = None,
) -> str {
    group: list[str] = [];
    for grp in groups {
        if plan_id in grp { group = grp; }
    }
    group_idx = 0;
    for (i, grp) in enumerate(groups) {
        if grp == group { group_idx = i + 1; }
    }
    gtype = group_types[group_idx - 1];
    position = merge_order.index(plan_id) + 1;
    total_positions = len(merge_order);
    peers: list[str] = [];
    for p in group {
        if p != plan_id { peers.append(p); }
    }
    peers = sorted(peers);
    peers_txt = ", ".join(peers) if peers else "None";
    idx = merge_order.index(plan_id);
    peer_ord = _peer_order_in_group(plan_id, group, merge_order);
    if idx == 0 or plan_id == peer_ord[0] {
        pred_line = "None — first in group";
    } else {
        prev = merge_order[idx - 1];
        pred_line = f"#{plan_to_issue[prev]} {plan_to_title[prev]}";
    }
    if idx == len(merge_order) - 1 {
        succ_line = "None — last in sequence";
    } else {
        nxt = merge_order[idx + 1];
        succ_line = f"#{plan_to_issue[nxt]} {plan_to_title[nxt]}";
    }
    gated = ", ".join(sorted(deferred or [])) or "None";
    return (
        "## Execution Context\n"
        + f"- **Dispatch group**: Group {group_idx} of {len(groups)}\n"
        + f"- **Group type**: {gtype}\n"
        + f"- **Dispatch position**: Position {position} of {total_positions}\n"
        + f"- **Immediate predecessor**: {pred_line}\n"
        + f"- **Immediate successor**: {succ_line}\n"
        + f"- **Group peers**: {peers_txt}\n"
        + f"- **Gated by**: {gated}\n"
    );
}
