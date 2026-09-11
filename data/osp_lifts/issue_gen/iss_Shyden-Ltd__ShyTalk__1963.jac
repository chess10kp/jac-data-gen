"""Shyden-Ltd/ShyTalk#1963 — resolved cohort never recomputed after date-of-birth gate."""

node Field {
    has name: str;
}

edge DependsOn: Field --> Field {}

obj ProfileStore {
    has users: dict[str, dict] = {};
    has values: dict[str, dict] = {};
    has session_cache: dict[str, str | None] = {};
    has fields: dict[str, Field] = {};
}

walker DownstreamWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];
    has origin: str = "";

    can step with Field entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        downs = [here <-:DependsOn:<-][?:Field];
        names: list[str] = [];
        for d in downs { names.append(d.name); }
        for nm in sorted(names) {
            for d in downs {
                if d.name == nm {
                    if d.name != self.origin {
                        already = False;
                        for h in self.hits { if h == d.name { already = True; } }
                        if not already { self.hits.append(d.name); }
                    }
                    if d.name not in self.claimed { visit [d]; }
                }
            }
        }
    }
}

walker TargetsCollectWalk {
    has claimed: dict[str, bool] = {};
    has targets: set[str] = set();

    can step with Field entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        downs = [here <-:DependsOn:<-][?:Field];
        names: list[str] = [];
        for d in downs { names.append(d.name); }
        for nm in sorted(names) {
            for d in downs {
                if d.name == nm {
                    self.targets.add(d.name);
                    if d.name not in self.claimed { visit [d]; }
                }
            }
        }
    }
}

walker DependsPathWalk {
    has target: str = "";
    has parent: dict[str, str | None] = {};
    has result: list[str] = [];

    can step with Field entry {
        if here.name == self.target {
            trail: list[str] = [];
            cur_nm: str = here.name;
            while True {
                trail.append(cur_nm);
                parent_nm = self.parent.get(cur_nm, None);
                if parent_nm is None { break; }
                cur_nm = parent_nm;
            }
            row: list[str] = [];
            idx = len(trail) - 1;
            while idx >= 0 {
                row.append(trail[idx]);
                idx -= 1;
            }
            self.result = row;
            skip;
        }
        downs = [here <-:DependsOn:<-][?:Field];
        names: list[str] = [];
        for d in downs { names.append(d.name); }
        for nm in sorted(names) {
            for d in downs {
                if d.name == nm and d.name not in self.parent {
                    self.parent[d.name] = here.name;
                    visit [d];
                }
            }
        }
    }
}

walker InvalidationTopoWalk {
    has changed: str = "";
    has targets: set[str] = set();
    has order: list[str] = [];
    has indeg: dict[str, int] = {};
    has ready: list[str] = [];
    has fields: dict[str, Field] = {};

    can begin with Root entry {
        for t in self.targets { self.indeg[t] = 0; }
        for t in self.targets {
            nd = self.fields.get(t, None);
            if nd is not None {
                for dep in [nd ->:DependsOn:->][?:Field] {
                    if dep.name in self.targets {
                        self.indeg[t] = self.indeg.get(t, 0) + 1;
                    }
                }
            }
        }
        seed: list[str] = [];
        for t in sorted(self.targets) {
            if self.indeg.get(t, 0) == 0 { seed.append(t); }
        }
        self.ready = seed;
        while len(self.ready) > 0 {
            cur = self.ready[0];
            rest: list[str] = [];
            idx = 1;
            while idx < len(self.ready) {
                rest.append(self.ready[idx]);
                idx += 1;
            }
            self.ready = rest;
            self.order.append(cur);
            nd = self.fields.get(cur, None);
            if nd is not None {
                downs = [nd <-:DependsOn:<-][?:Field];
                dnms: list[str] = [];
                for d in downs { dnms.append(d.name); }
                for nm in sorted(dnms) {
                    for d in downs {
                        if d.name == nm and d.name in self.targets {
                            self.indeg[d.name] = self.indeg.get(d.name, 0) - 1;
                            if self.indeg[d.name] == 0 {
                                self.ready.append(d.name);
                            }
                        }
                    }
                }
            }
            self.ready = sorted(self.ready);
        }
        report self.order;
    }
}

def _ensure_field(store: ProfileStore, name: str) -> Field {
    nd = store.fields.get(name, None);
    if nd is None {
        nd = Field(name=name);
        root ++> nd;
        store.fields[name] = nd;
    }
    return nd;
}

def _field_known(store: ProfileStore, name: str) -> bool {
    return name in store.fields;
}

def _has_dep_edge(from_nd: Field, to_nd: Field) -> bool {
    for d in [from_nd ->:DependsOn:->][?:Field] {
        if d.name == to_nd.name { return True; }
    }
    return False;
}

def load_profile_store(
    users: dict[str, dict],
    depends: list[tuple[str, str]],
) -> ProfileStore {
    store = ProfileStore();
    for uid in users {
        store.users[uid] = dict(users[uid]);
    }
    for (dependent, source) in depends {
        dep_nd = _ensure_field(store, dependent);
        src_nd = _ensure_field(store, source);
        if not _has_dep_edge(dep_nd, src_nd) { dep_nd +>:DependsOn:+> src_nd; }
    }
    return store;
}

def downstream_fields(store: ProfileStore, field: str) -> list[str] {
    if not _field_known(store, field) { return []; }
    nd = store.fields[field];
    w = nd spawn DownstreamWalk(claimed={}, hits=[], origin=field);
    return sorted(w.hits);
}

def depends_path(store: ProfileStore, src: str, dst: str) -> list[str] {
    if not _field_known(store, src) or not _field_known(store, dst) { return []; }
    nd = store.fields[src];
    parent: dict[str, str | None] = {src: None};
    w = nd spawn DependsPathWalk(target=dst, parent=parent, result=[]);
    return w.result;
}

def invalidation_order(store: ProfileStore, changed: str) -> list[str] {
    if not _field_known(store, changed) { return []; }
    nd = store.fields[changed];
    coll = nd spawn TargetsCollectWalk(claimed={}, targets=set());
    if not coll.targets { return []; }
    topo = root spawn InvalidationTopoWalk(
        changed=changed,
        targets=coll.targets,
        order=[],
        indeg={},
        ready=[],
        fields=store.fields,
    );
    return topo.order;
}

def effective_cohort(dob_year: int | None, ref_year: int = 2026) -> str | None {
    if dob_year is None { return "minor"; }
    if ref_year - dob_year < 18 { return "minor"; }
    return "adult";
}

def resolve_profile_state(
    store: ProfileStore, uid: str, ref_year: int = 2026
) -> str | None {
    if uid not in store.users { return None; }
    dob = store.users[uid].get("date_of_birth", None);
    eff = effective_cohort(dob, ref_year);
    if uid not in store.values { store.values[uid] = {}; }
    store.values[uid]["effective_cohort"] = eff;
    store.values[uid]["resolved_cohort"] = eff;
    store.session_cache[uid] = eff;
    store.values[uid]["session_cache"] = eff;
    return eff;
}

def complete_dob_gate(
    store: ProfileStore,
    uid: str,
    dob_year: int,
    ref_year: int = 2026,
    refresh_ok: bool = True,
) -> str | None {
    if uid not in store.users { return None; }
    store.users[uid]["date_of_birth"] = dob_year;
    if uid not in store.values { store.values[uid] = {}; }
    if not refresh_ok {
        store.values[uid]["resolved_cohort"] = None;
        store.values[uid]["session_cache"] = None;
        store.session_cache[uid] = None;
        return None;
    }
    for field in invalidation_order(store, "date_of_birth") {
        val: str | None = None;
        if field == "effective_cohort" {
            val = effective_cohort(dob_year, ref_year);
        } elif field == "resolved_cohort" {
            val = store.values[uid].get("effective_cohort", None);
        } elif field == "session_cache" {
            val = store.values[uid].get("resolved_cohort", None);
        } else {
            val = store.values[uid].get(field, None);
        }
        store.values[uid][field] = val;
        if field == "session_cache" { store.session_cache[uid] = val; }
    }
    return store.values[uid].get("resolved_cohort", None);
}

def read_resolved_cohort(store: ProfileStore, uid: str) -> str | None {
    if uid not in store.values { return None; }
    return store.values[uid].get("resolved_cohort", None);
}

def session_cache_cohort(store: ProfileStore, uid: str) -> str | None {
    return store.session_cache.get(uid, None);
}
