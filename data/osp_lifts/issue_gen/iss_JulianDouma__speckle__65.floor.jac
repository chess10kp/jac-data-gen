"""JulianDouma/speckle#65 — Native parent-child beads hierarchy."""
import from __future__ { annotations }
import from collections { deque }
class BeadsStore {
    def init(self: BeadsStore) -> None {
        self._issues: set[str] = `set();
        self._parent: dict[(str, (str | None))] = {};
        self._children: dict[(str, list[str])] = {};
    }
}
def load_beads(issues: list[str], parent_edges: list[tuple[(str, str)]]) -> BeadsStore {
    g = BeadsStore();
    for iid in issues {
        g._issues.add(iid);
        g._parent[iid] = None;
        g._children.setdefault(iid, []);
    }
    for (child, parent) in parent_edges {
        if ((child not in g._issues) or (parent not in g._issues)) {
            continue;
        }
        g._parent[child] = parent;
        g._children.setdefault(parent, []).append(child);
    }
    return g;
}
def direct_children(g: BeadsStore, parent_id: str) -> list[str] {
    if (parent_id not in g._issues) {
        return [];
    }
    return sorted(g._children.get(parent_id, []));
}
def subtree_ids(g: BeadsStore, root_id: str) -> list[str] {
    if (root_id not in g._issues) {
        return [];
    }
    q: deque[str] = deque([root_id]);
    claimed: set[str] = `set();
    hits: list[str] = [];
    while q {
        cur = q.popleft();
        if (cur in claimed) {
            continue;
        }
        claimed.add(cur);
        hits.append(cur);
        for ch in g._children.get(cur, []) {
            if (ch not in claimed) {
                q.append(ch);
            }
        }
    }
    return sorted(hits);
}
def rollup_stats(
    g: BeadsStore, root_id: str, statuses: dict[(str, str)]
) -> dict[(str, (int | str))] {
    ids = subtree_ids(g, root_id);
    if not ids {
        return {
            "children_count": 0,
            "children_closed": 0,
            "progress": 0,
            "status_rollup": "unknown"
        };
    }
    child_only = [
        i
        for i in ids
        if (i != root_id)
    ];
    closed = sum(
        1
        for i in child_only
        if (statuses.get(i) == "closed")
    );
    total = len(child_only);
    progress = int(((closed * 100) / total)) if total else 100;
    if (progress == 100) {
        rollup = "done";
    } elif (progress == 0) {
        rollup = "open";
    } else {
        rollup = "in_progress";
    }
    return {
        "children_count": total,
        "children_closed": closed,
        "progress": progress,
        "status_rollup": rollup
    };
}

