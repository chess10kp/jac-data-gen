"""Herd-OS/herd#1019 — workflow dispatch dependency frontier."""
import from __future__ { annotations }
class DispatchGraph {
    def init(self: DispatchGraph) -> None {
        self._jobs: set[str] = set();
        self._depends: dict[(str, list[str])] = {};
        self._status: dict[(str, str)] = {};
    }
}
def load_dispatch(
    jobs: list[str],
    depends_edges: list[tuple[(str, str)]],
    status: (dict[(str, str)] | None) = None
) -> DispatchGraph {
    g = DispatchGraph();
    for jid in jobs {
        g._jobs.add(jid);
        g._depends.setdefault(jid, []);
        g._status[jid] = "pending";
    }
    for (blocker, blocked) in depends_edges {
        if ((blocker in g._jobs) and (blocked in g._jobs)) {
            g._depends.setdefault(blocked, []).append(blocker);
        }
    }
    if status {
        for (k, v) in status.items() {
            if (k in g._jobs) {
                g._status[k] = v;
            }
        }
    }
    return g;
}
def _open_blockers(store: DispatchGraph, job: str) -> list[str] {
    blockers = store._depends.get(job, []);
    return sorted(
        b
        for b in blockers
        if (store._status.get(b) != "done")
    );
}
def frontier_jobs(store: DispatchGraph) -> list[str] {
    out: list[str] = [];
    for jid in sorted(store._jobs) {
        if (store._status.get(jid) != "pending") {
            continue;
        }
        if not _open_blockers(store, jid) {
            out.append(jid);
        }
    }
    return out;
}
def blocked_by(store: DispatchGraph, job: str) -> list[str] {
    if (job not in store._jobs) {
        return [];
    }
    return _open_blockers(store, job);
}
def dispatch_ready_count(store: DispatchGraph) -> int {
    return len(frontier_jobs(store));
}

