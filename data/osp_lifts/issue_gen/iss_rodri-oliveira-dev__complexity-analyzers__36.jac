"""rodri-oliveira-dev/complexity-analyzers#36 — analyzer execution order (OSP lift)."""

obj AnalyzerStore {
    has stamp: int = 0;
}

node Analyzer {
    has name: str;
}

edge Requires {}

walker UpstreamWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start: str = "";

    can begin with Root entry {
        for a in [-->][?:Analyzer] {
            if a.name == self.start {
                visit [a];
            }
        }
    }

    can step with Analyzer entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        if here.name != self.start {
            self.reached.append(here.name);
        }
        visit [here->:Requires:->][?:Analyzer];
    }

    can finish with Root exit {
        report self.reached;
    }
}

def _wire(analyzers: list[str], requires: list[tuple[str, str]]) {
    mp: dict[str, Analyzer] = {};
    for nm in analyzers {
        if nm not in mp {
            a = Analyzer(name=nm);
            root ++> a;
            mp[nm] = a;
        }
    }
    for (dst, src) in requires {
        d = mp.get(dst, None);
        s = mp.get(src, None);
        if d is not None and s is not None {
            dup = False;
            for up in [d ->:Requires:->][?:Analyzer] {
                if up.name == src {
                    dup = True;
                }
            }
            if not dup {
                d +>:Requires:+> s;
            }
        }
    }
}

def _analyzer(name: str) -> Analyzer | None {
    for a in [-->][?:Analyzer] {
        if a.name == name {
            return a;
        }
    }
    return None;
}

def load_analyzers(
    analyzers: list[str],
    requires: list[tuple[str, str]],
) -> AnalyzerStore {
    _wire(analyzers, requires);
    return AnalyzerStore(stamp=1);
}

def execution_waves(store: AnalyzerStore) -> list[list[str]] | None {
    _ = store;
    indeg: dict[str, int] = {};
    for a in [-->][?:Analyzer] {
        indeg[a.name] = len([a ->:Requires:->][?:Analyzer]);
    }
    waves: list[list[str]] = [];
    ready = sorted([nm for (nm, d) in indeg.items() if d == 0]);
    while ready {
        waves.append(ready);
        nxt: list[str] = [];
        for nm in ready {
            cur = _analyzer(nm);
            if cur is None {
                continue;
            }
            for dep in [cur <-:Requires:<-][?:Analyzer] {
                indeg[dep.name] -= 1;
                if indeg[dep.name] == 0 {
                    nxt.append(dep.name);
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

def required_analyzers(store: AnalyzerStore, analyzer: str) -> list[str] {
    _ = store;
    if _analyzer(analyzer) is None {
        return [];
    }
    w = root spawn UpstreamWalk(start=analyzer, claimed={}, reached=[]);
    return sorted(w.reports[0] if w.reports else []);
}
