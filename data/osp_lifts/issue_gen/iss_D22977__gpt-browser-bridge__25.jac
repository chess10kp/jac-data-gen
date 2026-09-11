"""D22977/gpt-browser-bridge#25 — Process ancestor chain with cycle guard."""

obj ProcessStore {
    has procs: dict[int, Process] = {};
}
node Process {
    has pid: int;
    has cmdline: str;
}
edge SpawnedBy {}

walker AncestorWalk {
    has claimed: dict[int, bool] = {};
    has chain: list[int] = [];
    can step with Process entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        self.chain.append(here.pid);
        parents = [here <-:SpawnedBy:<-][?:Process];
        if not parents { disengage; }
        pick = parents[0];
        for p in parents { if p.pid < pick.pid { pick = p; } }
        visit [pick];
    }
}

def load_processes(rows: list[tuple[int, int | None, str]]) -> ProcessStore {
    st = ProcessStore();
    for (pid, _parent, cmd) in rows {
        if pid not in st.procs {
            nd = Process(pid=pid, cmdline=cmd);
            root ++> nd;
            st.procs[pid] = nd;
        } else {
            st.procs[pid].cmdline = cmd;
        }
    }
    for (pid, parent, _cmd) in rows {
        c = st.procs.get(pid, None);
        if c is None { continue; }
        if parent is None { continue; }
        p = st.procs.get(parent, None);
        if p is None { continue; }
        p +>:SpawnedBy:+> c;
    }
    return st;
}

def ancestor_chain(st: ProcessStore, pid: int) -> list[int] {
    start = st.procs.get(pid, None);
    if start is None { return []; }
    w = start spawn AncestorWalk(claimed={}, chain=[]);
    return w.chain;
}

def forbidden_ancestors(
    st: ProcessStore,
    pid: int,
    patterns: list[str],
) -> list[int] {
    hits: list[int] = [];
    for anc in ancestor_chain(st, pid) {
        nd = st.procs.get(anc, None);
        if nd is None { continue; }
        low = nd.cmdline.lower();
        for pat in patterns {
            if pat.lower() in low { hits.append(anc); break; }
        }
    }
    return hits;
}
