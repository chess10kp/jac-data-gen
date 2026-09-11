"""Heliobond/backend#409 lifted to OSP: flag dependencies as DependsOn edges."""
node FlagNode {
    has name: str;
    has enabled: bool = False;
    has rollout: int = 100;
    has unresolved: list[str] = [];
}

edge DependsOn {}

obj FlagIndex {
    has flags: dict[str, FlagNode];
}

def build_flagset() -> FlagIndex {
    return FlagIndex(flags={});
}

def _wire(ix: FlagIndex, nd: FlagNode, deps: list) {
    olds: list[FlagNode] = [nd ->:DependsOn:->];
    for o in olds {
        nd del ->:DependsOn:-> o;
    }
    nd.unresolved = [];
    for d in deps {
        t = ix.flags.get(d);
        if t is None {
            nd.unresolved.append(d);
        } else {
            nd +>:DependsOn:+> t;
        }
    }
}

def _spec_enabled(raw: dict, dflt: bool) -> bool {
    v = raw.get("enabled");
    if v is None {
        return dflt;
    }
    return v;
}

def _spec_rollout(raw: dict, dflt: int) -> int {
    v = raw.get("rollout_percentage");
    if v is None {
        return dflt;
    }
    return v;
}

def _spec_deps(raw: dict) -> list {
    v = raw.get("depends_on");
    if v is None {
        return [];
    }
    out: list = [];
    for x in list(v) {
        out.append(x);
    }
    return out;
}

def merge(ix: FlagIndex, spec: dict) {
    # phase 1: ensure every node exists and carries its scalar fields
    names: list[str] = [];
    for k in spec.keys() {
        names.append(k);
    }
    for k in names {
        raw = spec.get(k);
        if raw is None {
            continue;
        }
        nd = ix.flags.get(k);
        if nd is None {
            nd = FlagNode(name=k);
            root ++> nd;
            ix.flags[k] = nd;
        }
        nd.enabled = _spec_enabled(raw, False);
        nd.rollout = _spec_rollout(raw, 100);
    }
    # phase 2: wire dependency edges now that all spec'd nodes exist
    for k in names {
        raw = spec.get(k);
        if raw is None {
            continue;
        }
        nd = ix.flags.get(k);
        if nd is not None {
            _wire(ix, nd, _spec_deps(raw));
        }
    }
    # phase 3: retry wiring for nodes holding names that were unknown earlier
    allnames: list[str] = [];
    for k in ix.flags.keys() {
        allnames.append(k);
    }
    for k in allnames {
        nd = ix.flags.get(k);
        if nd is not None {
            if len(nd.unresolved) > 0 {
                still: list[str] = [];
                for u in nd.unresolved {
                    t = ix.flags.get(u);
                    if t is None {
                        still.append(u);
                    } else {
                        nd +>:DependsOn:+> t;
                    }
                }
                nd.unresolved = still;
            }
        }
    }
}

def load(ix: FlagIndex, spec: dict) {
    ix.flags = {};
    merge(ix, spec);
}

"""Closure walk; a revisit within the evaluation is a cycle (the fix)."""
walker EvalWalk {
    has claimed: dict[str, bool];
    has bucket: int = 0;
    has revisited: bool = False;
    has failed: list[str] = [];
    has unknown: list[str] = [];

    can step with FlagNode entry {
        if here.name in self.claimed {
            self.revisited = True;
            skip;
        }
        self.claimed[here.name] = True;
        gate = here.enabled and self.bucket < here.rollout;
        if not gate {
            self.failed.append(here.name);
        }
        for u in here.unresolved {
            self.unknown.append(u);
        }
        visit [->:DependsOn:->];
    }
}

def evaluate(ix: FlagIndex, name: str, ctx: dict | None = None) -> dict {
    bucket = 0;
    if ctx is not None {
        b = ctx.get("bucket");
        if b is not None {
            bucket = b;
        }
    }
    f = ix.flags.get(name);
    res = dict();
    res["name"] = name;
    if f is None {
        res["value"] = False;
        res["reason"] = "unknown_flag";
        return res;
    }
    w = f spawn EvalWalk(claimed={}, bucket=bucket);
    if w.revisited {
        res["value"] = False;
        res["reason"] = "dependency_cycle";
        return res;
    }
    if len(w.unknown) > 0 {
        u = sorted(w.unknown);
        res["value"] = False;
        res["reason"] = "unknown_dependency:" + u[0];
        return res;
    }
    if len(w.failed) > 0 {
        fl = sorted(w.failed);
        res["value"] = False;
        res["reason"] = "gate:" + fl[0];
        return res;
    }
    res["value"] = True;
    res["reason"] = "ok";
    return res;
}
