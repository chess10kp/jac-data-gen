"""D22977/gpt-browser-bridge#25 — Process ancestor chain with cycle guard."""
import from __future__ { annotations }
class ProcessStore {
    def init(self: ProcessStore) -> None {
        self._parent: dict[(int, (int | None))] = {};
        self._cmdline: dict[(int, str)] = {};
    }
}
def load_processes(rows: list[tuple[(int, (int | None), str)]]) -> ProcessStore {
    st = ProcessStore();
    for (pid, parent, cmd) in rows {
        st._parent[pid] = parent;
        st._cmdline[pid] = cmd;
    }
    return st;
}
def ancestor_chain(st: ProcessStore, pid: int) -> list[int] {
    if (pid not in st._parent) {
        return [];
    }
    chain: list[int] = [pid];
    claimed: set[int] = {pid};
    cur = pid;
    while True {
        parent = st._parent.get(cur);
        if ((parent is None) or (parent in claimed)) {
            break;
        }
        claimed.add(parent);
        chain.append(parent);
        cur = parent;
    }
    return chain;
}
def forbidden_ancestors(st: ProcessStore, pid: int, patterns: list[str]) -> list[int] {
    hits: list[int] = [];
    for anc in ancestor_chain(st, pid) {
        cmd = st._cmdline.get(anc, "");
        low = cmd.lower();
        for pat in patterns {
            if (pat.lower() in low) {
                hits.append(anc);
                break;
            }
        }
    }
    return hits;
}

