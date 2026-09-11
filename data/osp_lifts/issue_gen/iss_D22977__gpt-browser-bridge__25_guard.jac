"""Guard: D22977/gpt-browser-bridge#25."""

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

test "ancestor chain upward" {
    st = load_processes([
        (100, 50, "GBB-REVIEWER pwsh"),
        (50, 10, "services.exe"),
        (10, None, "init"),
    ]);
    assert ancestor_chain(st, 100) == [100, 50, 10];
}

test "forbidden ORCA and worker" {
    st = load_processes([
        (7, 6, "worker ORCA probe"),
        (6, 5, "GBBWorker service"),
        (5, None, "init"),
    ]);
    assert forbidden_ancestors(st, 7, ["ORCA", "GBBWorker"]) == [7, 6];
}

test "cycle guard terminates" {
    st = load_processes([(1, 2, "a"), (2, 1, "b")]);
    assert ancestor_chain(st, 1) == [1, 2];
}

test "unknown pid tolerant" {
    st = load_processes([(1, None, "solo")]);
    assert ancestor_chain(st, 999) == [];
}
