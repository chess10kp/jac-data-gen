"""PostHog/posthog#64387 — Flag dependency blast-radius resolver."""

node Flag {
    has fid: str;
}

edge DependsOn {}

obj FlagStore {
    has flags: dict[str, Flag] = {};
}

walker DepWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has cyclic: bool = False;
    has anchor: str = "";

    can step with Flag entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        if here.fid != self.anchor {
            self.found.append(here.fid);
        }
        for nxt in [here ->:DependsOn:->][?:Flag] {
            if nxt.fid in self.claimed {
                self.cyclic = True;
            }
        }
        if self.cyclic { disengage; }
        visit [->:DependsOn:->][?:Flag];
    }
}

def load_flags(
    flag_ids: list[str],
    depends_edges: list[tuple[str, str]],
) -> FlagStore {
    fs = FlagStore();
    for fid in flag_ids {
        nd = Flag(fid=fid);
        root ++> nd;
        fs.flags[fid] = nd;
    }
    for (parent, dep) in depends_edges {
        p = fs.flags.get(parent, None);
        d = fs.flags.get(dep, None);
        if p is not None and d is not None { p +>:DependsOn:+> d; }
    }
    return fs;
}

def resolve_dependency_chain(
    store: FlagStore,
    flag_id: str,
    _seen: set[str] | None = None,
) -> list[str] | None {
    if flag_id not in store.flags { return None; }
    if _seen is not None and flag_id in _seen { return None; }
    nd = store.flags[flag_id];
    w = nd spawn DepWalk(claimed={}, found=[], cyclic=False, anchor=flag_id);
    if w.cyclic { return None; }
    return sorted(w.found);
}

def blast_radius_ids(store: FlagStore, flag_id: str) -> list[str] {
    chain = resolve_dependency_chain(store, flag_id, set());
    if chain is None { return []; }
    out = list(chain);
    out.append(flag_id);
    return sorted(out);
}

def missing_dependency(store: FlagStore, flag_id: str, dep_key: str) -> bool {
    if flag_id not in store.flags { return True; }
    return dep_key not in store.flags;
}
