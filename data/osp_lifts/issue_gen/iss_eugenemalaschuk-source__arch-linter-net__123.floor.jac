"""eugenemalaschuk-source/arch-linter-net#123 — Release milestone dependency DAG."""
import from __future__ { annotations }
import from collections { deque }
class MilestoneGraph {
    def init(self: MilestoneGraph) -> None {
        self._milestones: set[str] = `set();
        self._blockers: dict[(str, set[str])] = {};
        self._dependents: dict[(str, set[str])] = {};
    }
}
def load_milestones(
    milestones: list[str], depends: list[tuple[(str, str)]]
) -> MilestoneGraph {
    g = MilestoneGraph();
    for mid in milestones {
        g._milestones.add(mid);
        g._blockers.setdefault(mid, `set());
        g._dependents.setdefault(mid, `set());
    }
    for (blocker, dependent) in depends {
        if ((blocker not in g._milestones) or (dependent not in g._milestones)) {
            continue;
        }
        g._blockers[dependent].add(blocker);
        g._dependents[blocker].add(dependent);
    }
    return g;
}
def is_reachable(g: MilestoneGraph, src: str, dst: str) -> bool {
    if ((src not in g._milestones) or (dst not in g._milestones)) {
        return False;
    }
    q: deque[str] = deque([src]);
    seen: set[str] = `set();
    while q {
        cur = q.popleft();
        if (cur == dst) {
            return True;
        }
        if (cur in seen) {
            continue;
        }
        seen.add(cur);
        for nxt in g._dependents.get(cur, ()) {
            if (nxt not in seen) {
                q.append(nxt);
            }
        }
    }
    return False;
}
def execution_order(g: MilestoneGraph) -> list[str] {
    indeg: dict[(str, int)] = {m: len(g._blockers[m]) for m in g._milestones};
    q: deque[str] = deque(
        sorted(
            m
            for (m, d) in indeg.items()
            if (d == 0)
        )
    );
    out: list[str] = [];
    while q {
        cur = q.popleft();
        out.append(cur);
        for dep in sorted(g._dependents.get(cur, ())) {
            indeg[dep] -= 1;
            if (indeg[dep] == 0) {
                q.append(dep);
            }
        }
        q = deque(sorted(q));
    }
    return out if (len(out) == len(g._milestones)) else [];
}
def pending_blockers(
    g: MilestoneGraph, milestone: str, shipped: set[str]
) -> list[str] {
    if (milestone not in g._milestones) {
        return [];
    }
    pending = [
        b
        for b in sorted(g._blockers[milestone])
        if (b not in shipped)
    ];
    return pending;
}

