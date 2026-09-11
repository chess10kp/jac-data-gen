"""OSP lift for AxiomaSystems/Chef#80 — beta hardening execution order."""

node Task {
    has name: str;
}

edge Depends {}

walker TopoWalker {
    has order: list[str] = [];
    has claimed: dict[str, bool] = {};
    has indegree: dict[str, int] = {};
    has seeds: list[str] = [];

    can begin with Root entry {
        for seed in self.seeds {
            for t in [-->][?:Task] {
                if t.name == seed {
                    visit [t];
                }
            }
        }
    }

    can step with Task entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.order.append(here.name);
        for nxt in [-->][?:Task] {
            nm = nxt.name;
            self.indegree[nm] = self.indegree.get(nm, 0) - 1;
            if self.indegree.get(nm, 0) == 0 {
                visit [nxt];
            }
        }
    }

    can finish with Root exit {
        report self.order;
    }
}

def _wire(tasks: list[str], depends: list[tuple[str, str]]) -> dict[str, int] {
    nodes: dict[str, Task] = {};
    indeg: dict[str, int] = {};
    for t in tasks {
        nodes[t] = Task(name=t);
        root ++> nodes[t];
        indeg[t] = 0;
    }
    for (a, b) in depends {
        nodes[a] +>:Depends:+> nodes[b];
        indeg[b] = indeg.get(b, 0) + 1;
    }
    return indeg;
}

def execution_order(tasks: list[str], depends: list[tuple[str, str]]) -> list[str] {
    indeg = _wire(tasks, depends);
    seeds = sorted([t for t in tasks if indeg.get(t, 0) == 0]);
    w = root spawn TopoWalker(indegree=indeg, seeds=seeds);
    return w.reports[0] if w.reports else [];
}

def hardening_ready(task: str, completed: set[str], depends: list[tuple[str, str]]) -> bool {
    for (a, b) in depends {
        if b == task and a not in completed {
            return False;
        }
    }
    return True;
}

def tasks_by_owner(owners: dict[str, str]) -> dict[str, list[str]] {
    out: dict[str, list[str]] = {};
    for (task, owner) in sorted(owners.items()) {
        if owner not in out {
            out[owner] = [];
        }
        out[owner].append(task);
    }
    for owner in out {
        out[owner] = sorted(out[owner]);
    }
    return out;
}
