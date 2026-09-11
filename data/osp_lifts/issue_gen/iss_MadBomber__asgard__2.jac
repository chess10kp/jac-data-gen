"""MadBomber/asgard#2 — parallel waves from typed Depends edges."""
obj DagStore { has stamp: int = 0; }
node Task { has name: str; }
edge Depends {}

walker CycleProbe {
    has color: dict[str, int] = {};
    has hit: dict[str, bool] = {};
    can step with Task entry {
        if "found" in self.hit and self.hit["found"] { disengage; }
        c = self.color.get(here.name, 0);
        if c == 1 { self.hit["found"] = True; disengage; }
        if c == 2 { skip; }
        self.color[here.name] = 1;
        visit [->:Depends:->][?:Task];
        self.color[here.name] = 2;
    }
}

def load_dag(tasks: list[str], edges: list[tuple[str, str]]) -> DagStore {
    mp: dict[str, Task] = {};
    for t in tasks { n = Task(name=t); root ++> n; mp[t] = n; }
    for (a, b) in edges {
        src = mp.get(a, None); dst = mp.get(b, None);
        if src is not None and dst is not None { src +>:Depends:+> dst; }
    }
    return DagStore(stamp=1);
}

def _task(name: str) -> Task | None {
    for t in [-->][?:Task] { if t.name == name { return t; } }
    return None;
}

def has_cycle(g: DagStore) -> bool {
    _ = g;
    for t in [-->][?:Task] {
        w = t spawn CycleProbe(color={}, hit={});
        if "found" in w.hit and w.hit["found"] { return True; }
    }
    return False;
}

def parallel_waves(g: DagStore) -> list[list[str]] | None {
    _ = g;
    if has_cycle(g) { return None; }
    indeg: dict[str, int] = {};
    for t in [-->][?:Task] { indeg[t.name] = len([t <-:Depends:<-][?:Task]); }
    waves: list[list[str]] = [];
    ready = sorted([n for (n, d) in indeg.items() if d == 0]);
    while ready {
        waves.append(ready);
        nxt: list[str] = [];
        for nm in ready {
            node = _task(nm);
            if node is None { continue; }
            for dep in [node ->:Depends:->][?:Task] {
                indeg[dep.name] -= 1;
                if indeg[dep.name] == 0 { nxt.append(dep.name); }
            }
        }
        ready = sorted(nxt);
    }
    total = 0;
    for w in waves { total += len(w); }
    return waves if total == len(indeg) else None;
}
