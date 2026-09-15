"""joerick/pyinstrument#293 — flat and cumulative profile times over call graphs."""

node Func {
    has fid: str;
    has self_ms: float = 0.0;
}

edge Calls {}

node Hub {
    has tag: str = "hub";
}

obj Profile {
    has nodes: dict[str, Func] = {};
    has hub: Hub;
}

walker DoneWalker {
    has label: str;

    can done with Hub entry {
        print ["done", self.label];
        disengage;
    }
}

walker FlatWalker {
    has claimed: dict[str, bool] = {};
    has out: dict[str, float] = {};

    can tally with Func entry {
        if here.fid in self.claimed {
            skip;
        }
        self.claimed[here.fid] = True;
        self.out[here.fid] = here.self_ms;
        print ["flat", here.fid, here.self_ms];
        kids: list[Func] = [here ->:Calls:->][?:Func];
        for ch in kids {
            visit :0: [ch];
        }
    }
}

walker CumWalker {
    has claimed: dict[str, bool] = {};
    has out: dict[str, float] = {};

    can climb with Func entry {
        if here.fid in self.claimed {
            skip;
        }
        self.claimed[here.fid] = True;
        sub: float = 0.0;
        kids: list[Func] = [here ->:Calls:->][?:Func];
        for ch in kids {
            visit :0: [ch];
            cid: str = ch.fid;
            if cid in self.out {
                sub += self.out[cid];
            }
        }
        tot: float = here.self_ms + sub;
        self.out[here.fid] = tot;
        print ["cum", here.fid, tot];
    }
}

def make_profile(
    specs: list[tuple[str, float]], links: list[tuple[str, str]]
) -> Profile {
    hub = Hub();
    root ++> hub;
    store: dict[str, Func] = {};
    for row in specs {
        fid: str = row[0];
        ms: float = row[1];
        nd = Func(fid=fid, self_ms=ms);
        store[fid] = nd;
        root ++> nd;
    }
    for row in links {
        src: str = row[0];
        dst: str = row[1];
        if src not in store {
            continue;
        }
        if dst not in store {
            continue;
        }
        a = store[src] as Func;
        b = store[dst] as Func;
        a +>:Calls:+> b;
    }
    return Profile(nodes=store, hub=hub);
}

def flat_times(prof: Profile) -> dict[str, float] {
    claimed: dict[str, bool] = {};
    out: dict[str, float] = {};
    keys: list[str] = sorted(prof.nodes.keys());
    start: Func = prof.nodes[keys[0]] as Func;
    start spawn FlatWalker(claimed=claimed, out=out);
    root spawn DoneWalker(label="flat_times");
    return out;
}

def cum_times(prof: Profile, root_id: str) -> dict[str, float] {
    if root_id not in prof.nodes {
        return {};
    }
    claimed: dict[str, bool] = {};
    out: dict[str, float] = {};
    start: Func = prof.nodes[root_id] as Func;
    start spawn CumWalker(claimed=claimed, out=out);
    root spawn DoneWalker(label="cum_times");
    return out;
}

def top_cum(prof: Profile, root_id: str, limit: int) -> list[tuple[str, float]] {
    ct: dict[str, float] = cum_times(prof, root_id);
    if len(ct) == 0 {
        return [];
    }
    names: list[str] = sorted(ct.keys());
    ranked: list[tuple[str, float]] = [];
    for nm in names {
        ranked.append((nm, ct[nm]));
    }
    picked: list[tuple[str, float]] = [];
    used: dict[str, bool] = {};
    n: int = 0;
    while n < limit and n < len(ranked) {
        best_i: int = -1;
        best_ms: float = -1.0;
        best_name: str = "";
        i: int = 0;
        while i < len(ranked) {
            row = ranked[i];
            nm2: str = row[0];
            if nm2 not in used {
                if row[1] > best_ms or (row[1] == best_ms and (best_i < 0 or nm2 < best_name)) {
                    best_i = i;
                    best_ms = row[1];
                    best_name = nm2;
                }
            }
            i += 1;
        }
        if best_i < 0 {
            break;
        }
        pick = ranked[best_i];
        picked.append(pick);
        used[pick[0]] = True;
        n += 1;
    }
    return picked;
}

"""joerick/pyinstrument#293 — flat and cumulative profile times over call graphs."""

node Func {
    has fid: str;
    has self_ms: float = 0.0;
}

edge Calls {}

node Hub {
    has tag: str = "hub";
}

obj Profile {
    has nodes: dict[str, Func] = {};
    has hub: Hub;
}

walker DoneWalker {
    has label: str;

    can done with Hub entry {
        print ["done", self.label];
        disengage;
    }
}

walker FlatWalker {
    has claimed: dict[str, bool] = {};
    has out: dict[str, float] = {};

    can tally with Func entry {
        if here.fid in self.claimed {
            skip;
        }
        self.claimed[here.fid] = True;
        self.out[here.fid] = here.self_ms;
        print ["flat", here.fid, here.self_ms];
        kids: list[Func] = [here ->:Calls:->][?:Func];
        for ch in kids {
            visit :0: [ch];
        }
    }
}

walker CumWalker {
    has claimed: dict[str, bool] = {};
    has out: dict[str, float] = {};

    can climb with Func entry {
        if here.fid in self.claimed {
            skip;
        }
        self.claimed[here.fid] = True;
        sub: float = 0.0;
        kids: list[Func] = [here ->:Calls:->][?:Func];
        for ch in kids {
            visit :0: [ch];
            cid: str = ch.fid;
            if cid in self.out {
                sub += self.out[cid];
            }
        }
        tot: float = here.self_ms + sub;
        self.out[here.fid] = tot;
        print ["cum", here.fid, tot];
    }
}

def make_profile(
    specs: list[tuple[str, float]], links: list[tuple[str, str]]
) -> Profile {
    hub = Hub();
    root ++> hub;
    store: dict[str, Func] = {};
    for row in specs {
        fid: str = row[0];
        ms: float = row[1];
        nd = Func(fid=fid, self_ms=ms);
        store[fid] = nd;
        root ++> nd;
    }
    for row in links {
        src: str = row[0];
        dst: str = row[1];
        if src not in store {
            continue;
        }
        if dst not in store {
            continue;
        }
        a = store[src] as Func;
        b = store[dst] as Func;
        a +>:Calls:+> b;
    }
    return Profile(nodes=store, hub=hub);
}

def flat_times(prof: Profile) -> dict[str, float] {
    claimed: dict[str, bool] = {};
    out: dict[str, float] = {};
    keys: list[str] = sorted(prof.nodes.keys());
    start: Func = prof.nodes[keys[0]] as Func;
    start spawn FlatWalker(claimed=claimed, out=out);
    root spawn DoneWalker(label="flat_times");
    return out;
}

def cum_times(prof: Profile, root_id: str) -> dict[str, float] {
    if root_id not in prof.nodes {
        return {};
    }
    claimed: dict[str, bool] = {};
    out: dict[str, float] = {};
    start: Func = prof.nodes[root_id] as Func;
    start spawn CumWalker(claimed=claimed, out=out);
    root spawn DoneWalker(label="cum_times");
    return out;
}

def top_cum(prof: Profile, root_id: str, limit: int) -> list[tuple[str, float]] {
    ct: dict[str, float] = cum_times(prof, root_id);
    if len(ct) == 0 {
        return [];
    }
    names: list[str] = sorted(ct.keys());
    ranked: list[tuple[str, float]] = [];
    for nm in names {
        ranked.append((nm, ct[nm]));
    }
    picked: list[tuple[str, float]] = [];
    used: dict[str, bool] = {};
    n: int = 0;
    while n < limit and n < len(ranked) {
        best_i: int = -1;
        best_ms: float = -1.0;
        best_name: str = "";
        i: int = 0;
        while i < len(ranked) {
            row = ranked[i];
            nm2: str = row[0];
            if nm2 not in used {
                if row[1] > best_ms or (row[1] == best_ms and (best_i < 0 or nm2 < best_name)) {
                    best_i = i;
                    best_ms = row[1];
                    best_name = nm2;
                }
            }
            i += 1;
        }
        if best_i < 0 {
            break;
        }
        pick = ranked[best_i];
        picked.append(pick);
        used[pick[0]] = True;
        n += 1;
    }
    return picked;
}

test "make_profile_nodes" {
    specs: list[tuple[str, float]] = [("main", 1.0), ("work", 2.0)];
    links: list[tuple[str, str]] = [("main", "work")];
    prof = make_profile(specs, links);
    assert (len(prof.nodes) == 2);;
    assert (prof.nodes["main"].self_ms == 1.0);;
    assert (prof.nodes["work"].self_ms == 2.0);;
}

test "flat_times_self" {
    specs: list[tuple[str, float]] = [("a", 10.0), ("b", 5.0), ("c", 3.0)];
    links: list[tuple[str, str]] = [("a", "b"), ("b", "c")];
    prof = make_profile(specs, links);
    ft = flat_times(prof);
    assert (ft["a"] == 10.0);;
    assert (ft["b"] == 5.0);;
    assert (ft["c"] == 3.0);;
    assert (len(ft) == 3);;
}

test "cum_times_tree" {
    specs: list[tuple[str, float]] = [("a", 10.0), ("b", 5.0), ("c", 3.0)];
    links: list[tuple[str, str]] = [("a", "b"), ("b", "c")];
    prof = make_profile(specs, links);
    ct = cum_times(prof, "a");
    assert (ct["c"] == 3.0);;
    assert (ct["b"] == 8.0);;
    assert (ct["a"] == 18.0);;
}

test "cum_times_unknown_root" {
    specs: list[tuple[str, float]] = [("a", 1.0)];
    links: list[tuple[str, str]] = [];
    prof = make_profile(specs, links);
    ct = cum_times(prof, "missing");
    assert (len(ct) == 0);;
}

test "top_cum_ranking" {
    specs: list[tuple[str, float]] = [("a", 10.0), ("b", 5.0), ("c", 3.0)];
    links: list[tuple[str, str]] = [("a", "b"), ("b", "c")];
    prof = make_profile(specs, links);
    top = top_cum(prof, "a", 2);
    assert (len(top) == 2);;
    assert (top[0][0] == "a");;
    assert (top[0][1] == 18.0);;
    assert (top[1][0] == "b");;
    assert (top[1][1] == 8.0);;
}

test "cum_times_cycle_skip" {
    specs: list[tuple[str, float]] = [("a", 4.0), ("b", 2.0)];
    links: list[tuple[str, str]] = [("a", "b"), ("b", "a")];
    prof = make_profile(specs, links);
    ct = cum_times(prof, "a");
    assert (ct["a"] == 6.0);;
    assert (ct["b"] == 2.0);;
}
