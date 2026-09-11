"""serrrfirat/bottega#165 — Work-item depends_on chains with fail-closed propagation.

Work items form a singly-linked depends_on chain. Claim skips items whose
dependency is not done; blocking a parent cascades block status to dependents
via a collect-then-apply walk outside traversal.
"""
import from __future__ { annotations }
class WorkQueue {
    def init(self: WorkQueue) -> None {
        self.parent_of: dict[(str, (str | None))] = {};
        self.children_of: dict[(str, list[str])] = {};
        self.status: dict[(str, str)] = {};
    }
}
def load_queue(
    items: list[str], depends: list[tuple[(str, str)]], status: dict[(str, str)]
) -> WorkQueue {
    q = WorkQueue();
    for iid in items {
        q.parent_of[iid] = None;
        q.children_of.setdefault(iid, []);
        q.status[iid] = status.get(iid, "open");
    }
    for (child, parent) in depends {
        if ((child in q.parent_of) and (parent in q.parent_of)) {
            q.parent_of[child] = parent;
            q.children_of.setdefault(parent, []).append(child);
        }
    }
    return q;
}
def claimable(q: WorkQueue, item_id: str) -> bool {
    if (item_id not in q.status) {
        return False;
    }
    if (q.status[item_id] != "open") {
        return False;
    }
    dep = q.parent_of.get(item_id);
    if (dep is None) {
        return True;
    }
    return (q.status.get(dep) == "done");
}
def _collect_dependents(q: WorkQueue, root_id: str) -> list[str] {
    stack = [root_id];
    seen: set[str] = `set();
    out: list[str] = [];
    while stack {
        cur = stack.pop();
        if (cur in seen) {
            continue;
        }
        seen.add(cur);
        out.append(cur);
        for ch in q.children_of.get(cur, []) {
            stack.append(ch);
        }
    }
    return out;
}
def propagate_block(q: WorkQueue, item_id: str) -> list[str] {
    if (item_id not in q.status) {
        raise KeyError("unknown item");
    }
    q.status[item_id] = "blocked";
    changed: list[str] = [item_id];
    for dep_id in _collect_dependents(q, item_id) {
        if (dep_id == item_id) {
            continue;
        }
        if (q.status.get(dep_id) not in ("blocked", "aborted")) {
            q.status[dep_id] = "blocked";
            changed.append(dep_id);
        }
    }
    return sorted(changed);
}
def mark_done(q: WorkQueue, item_id: str) -> None {
    if (item_id in q.status) {
        q.status[item_id] = "done";
    }
}

