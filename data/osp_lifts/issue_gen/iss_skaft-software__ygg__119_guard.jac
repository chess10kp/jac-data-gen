"""skaft-software/ygg#119 — candidate + hidden guards."""

obj WorkflowStore {
    has stamp: int = 0;
}

node Phase {
    has name: str;
}

edge Requires {}

walker DownstreamWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start: str = "";

    can begin with Root entry {
        for p in [-->][?:Phase] {
            if p.name == self.start {
                visit [p];
            }
        }
    }

    can step with Phase entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        if here.name != self.start {
            self.reached.append(here.name);
        }
        visit [<-:Requires:<-][?:Phase];
    }

    can finish with Root exit {
        report self.reached;
    }
}

def _wire(phases: list[str], requires: list[tuple[str, str]]) {
    mp: dict[str, Phase] = {};
    for nm in phases {
        if nm not in mp {
            p = Phase(name=nm);
            root ++> p;
            mp[nm] = p;
        }
    }
    for (dst, src) in requires {
        d = mp.get(dst, None);
        s = mp.get(src, None);
        if d is not None and s is not None {
            d +>:Requires:+> s;
        }
    }
}

def _phase(name: str) -> Phase | None {
    for p in [-->][?:Phase] {
        if p.name == name {
            return p;
        }
    }
    return None;
}

def load_workflow(
    phases: list[str],
    requires: list[tuple[str, str]],
) -> WorkflowStore {
    _wire(phases, requires);
    return WorkflowStore(stamp=1);
}

def phase_waves(wf: WorkflowStore) -> list[list[str]] | None {
    _ = wf;
    indeg: dict[str, int] = {};
    for p in [-->][?:Phase] {
        indeg[p.name] = len([p ->:Requires:->][?:Phase]);
    }
    waves: list[list[str]] = [];
    ready = sorted([nm for (nm, d) in indeg.items() if d == 0]);
    while ready {
        waves.append(ready);
        nxt: list[str] = [];
        for nm in ready {
            cur = _phase(nm);
            if cur is None {
                continue;
            }
            for dep in [cur <-:Requires:<-][?:Phase] {
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

def downstream_phases(wf: WorkflowStore, phase: str) -> list[str] {
    _ = wf;
    if _phase(phase) is None {
        return [];
    }
    w = root spawn DownstreamWalk(start=phase, claimed={}, reached=[]);
    return sorted(w.reports[0] if w.reports else []);
}

test "ygg workflow phase waves and downstream reach" {
    wf = load_workflow(
        [
            "inspect_plan",
            "investigate_fanout",
            "synthesize",
            "serialized_writer",
            "deterministic_checks",
            "repair_loop",
            "evidence_gate",
        ],
        [
            ("investigate_fanout", "inspect_plan"),
            ("synthesize", "investigate_fanout"),
            ("serialized_writer", "synthesize"),
            ("deterministic_checks", "serialized_writer"),
            ("repair_loop", "deterministic_checks"),
            ("evidence_gate", "repair_loop"),
        ],
    );
    assert phase_waves(wf) == [
        ["inspect_plan"],
        ["investigate_fanout"],
        ["synthesize"],
        ["serialized_writer"],
        ["deterministic_checks"],
        ["repair_loop"],
        ["evidence_gate"],
    ];
    assert downstream_phases(wf, "inspect_plan") == [
        "deterministic_checks",
        "evidence_gate",
        "investigate_fanout",
        "repair_loop",
        "serialized_writer",
        "synthesize",
    ];
}

test "cycle returns none waves" {
    wf = load_workflow(
        ["a", "b", "c"],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert phase_waves(wf) is None;
}

test "unknown phase tolerant" {
    wf = load_workflow(["only"], []);
    assert downstream_phases(wf, "missing") == [];
}

test "adversarial diamond downstream once per phase" {
    # Edge insertion order forces shared-base revisit before deeper first-visits.
    wf = load_workflow(
        ["top", "left", "right", "base", "leaf"],
        [
            ("top", "right"),
            ("base", "leaf"),
            ("left", "base"),
            ("top", "left"),
            ("right", "base"),
        ],
    );
    assert downstream_phases(wf, "leaf") == ["base", "left", "right", "top"];
}
