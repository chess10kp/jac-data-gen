"""Dtronix/Quarry#330 — employee manager tree descendant enumeration."""
import from __future__ { annotations }
import from collections { deque }
class OrgStore {
    def init(self: OrgStore) -> None {
        self._employees: set[str] = set();
        self._manager: dict[(str, (str | None))] = {};
        self._reports: dict[(str, list[str])] = {};
    }
}
def load_org(employees: list[str], manager_edges: list[tuple[(str, str)]]) -> OrgStore {
    store = OrgStore();
    for eid in employees {
        store._employees.add(eid);
        store._manager[eid] = None;
        store._reports.setdefault(eid, []);
    }
    for (mgr, rep) in manager_edges {
        if ((mgr in store._employees) and (rep in store._employees)) {
            store._manager[rep] = mgr;
            store._reports.setdefault(mgr, []).append(rep);
        }
    }
    return store;
}
def manager_descendants(store: OrgStore, emp_id: str) -> list[str] {
    if (emp_id not in store._employees) {
        return [];
    }
    seen: set[str] = set();
    queue: deque[str] = deque(store._reports.get(emp_id, []));
    while queue {
        cur = queue.popleft();
        if (cur in seen) {
            continue;
        }
        seen.add(cur);
        for rep in store._reports.get(cur, []) {
            if (rep not in seen) {
                queue.append(rep);
            }
        }
    }
    return sorted(seen);
}
def reporting_depth(store: OrgStore, emp_id: str) -> int {
    if (emp_id not in store._employees) {
        return -1;
    }
    depth = 0;
    cur: (str | None) = emp_id;
    seen: set[str] = set();
    while (cur is not None) {
        if (cur in seen) {
            return -1;
        }
        seen.add(cur);
        mgr = store._manager.get(cur);
        if (mgr is None) {
            break;
        }
        depth += 1;
        cur = mgr;
    }
    return depth;
}
def direct_reports(store: OrgStore, emp_id: str) -> list[str] {
    if (emp_id not in store._employees) {
        return [];
    }
    return sorted(store._reports.get(emp_id, []));
}

