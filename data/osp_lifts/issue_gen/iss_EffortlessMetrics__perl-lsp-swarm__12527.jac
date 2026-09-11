"""EffortlessMetrics/perl-lsp-swarm#12527 — compile-time module dependency lift."""

obj ProjectStore {
    has stamp: int = 0;
}

node Module {
    has mid: str;
}

edge UseDep {}

walker ClosureWalker {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start: str = "";

    can begin with Root entry {
        for m in [-->][?:Module] {
            if m.mid == self.start {
                visit [m];
            }
        }
    }

    can step with Module entry {
        if here.mid in self.claimed {
            skip;
        }
        self.claimed[here.mid] = True;
        self.reached.append(here.mid);
        visit [->:UseDep:->][?:Module];
    }

    can finish with Root exit {
        report self.reached;
    }
}

walker CycleProbe {
    has color: dict[str, int] = {};
    has found: bool = False;

    can step with Module entry {
        if self.found {
            disengage;
        }
        c = self.color.get(here.mid, 0);
        if c == 1 {
            self.found = True;
            disengage;
        }
        if c == 2 {
            skip;
        }
        self.color[here.mid] = 1;
        visit [->:UseDep:->][?:Module];
        self.color[here.mid] = 2;
    }
}

def _wire(modules: list[str], use_edges: list[tuple[str, str]]) {
    mp: dict[str, Module] = {};
    for mid in modules {
        if mid not in mp {
            n = Module(mid=mid);
            root ++> n;
            mp[mid] = n;
        }
    }
    for (consumer, dep) in use_edges {
        c = mp.get(consumer, None);
        d = mp.get(dep, None);
        if c is not None and d is not None {
            c +>:UseDep:+> d;
        }
    }
}

def _mod(mid: str) -> Module | None {
    for m in [-->][?:Module] {
        if m.mid == mid {
            return m;
        }
    }
    return None;
}

def load_project(
    modules: list[str],
    use_edges: list[tuple[str, str]],
) -> ProjectStore {
    _wire(modules, use_edges);
    return ProjectStore(stamp=1);
}

def _has_cycle() -> bool {
    for m in [-->][?:Module] {
        w = m spawn CycleProbe(color={}, found=False);
        if w.found {
            return True;
        }
    }
    return False;
}

def has_import_cycle(g: ProjectStore) -> bool {
    _ = g;
    return _has_cycle();
}

def module_closure(g: ProjectStore, module: str) -> list[str] {
    _ = g;
    if _mod(module) is None {
        return [];
    }
    w = root spawn ClosureWalker(start=module, claimed={}, reached=[]);
    raw = w.reports[0] if w.reports else [];
    return sorted(raw);
}

def compile_waves(g: ProjectStore) -> list[list[str]] | None {
    _ = g;
    if _has_cycle() {
        return None;
    }
    indeg: dict[str, int] = {};
    for m in [-->][?:Module] {
        indeg[m.mid] = len([m ->:UseDep:->][?:Module]);
    }
    waves: list[list[str]] = [];
    ready = sorted([mid for (mid, d) in indeg.items() if d == 0]);
    while ready {
        waves.append(ready);
        nxt: list[str] = [];
        for nm in ready {
            cur = _mod(nm);
            if cur is None {
                continue;
            }
            for dep in [cur <-:UseDep:<-][?:Module] {
                indeg[dep.mid] -= 1;
                if indeg[dep.mid] == 0 {
                    nxt.append(dep.mid);
                }
            }
        }
        ready = sorted(nxt);
    }
    total = 0;
    for w in waves {
        total += len(w);
    }
    return waves if total == len(indeg) else None;
}
