"""Tr3kkR/Yuzu#346 — candidate + hidden guards."""

obj GroupStore { has stamp: int = 0; }
node Group { has gid: str; }
edge ChildOf {}

walker Descendants {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has start: str = "";
    can begin with Root entry {
        for grp in [-->][?:Group] { if grp.gid == self.start { visit [grp]; } }
    }
    can step with Group entry {
        if here.gid in self.claimed { skip; }
        self.claimed[here.gid] = True;
        if here.gid != self.start { self.found.append(here.gid); }
        visit [->:ChildOf:->][?:Group];
    }
    can finish with Root exit { report self.found; }
}

def _wire(groups: list[tuple[str, str | None]]) -> dict[str, Group] {
    mp: dict[str, Group] = {};
    for (gid, _par) in groups {
        if gid not in mp { n = Group(gid=gid); root ++> n; mp[gid] = n; }
    }
    for (gid, par) in groups {
        if par is None { continue; }
        if par not in mp { p = Group(gid=par); root ++> p; mp[par] = p; }
        mp[par] +>:ChildOf:+> mp[gid];
    }
    return mp;
}

def _group(gid: str) -> Group | None {
    for g in [-->][?:Group] { if g.gid == gid { return g; } }
    return None;
}

def load_groups(groups: list[tuple[str, str | None]]) -> GroupStore {
    _wire(groups);
    return GroupStore(stamp=1);
}

def descendant_ids(g: GroupStore, start: str) -> list[str] {
    _ = g;
    if _group(start) is None { return []; }
    w = root spawn Descendants(start=start, claimed={}, found=[]);
    return sorted(w.reports[0] if w.reports else []);
}

def ancestor_ids(g: GroupStore, start: str) -> list[str] {
    _ = g;
    cur = _group(start);
    if cur is None { return []; }
    out: list[str] = [];
    seen: dict[str, bool] = {};
    while True {
        par: Group | None = None;
        for p in [cur <-:ChildOf:<-][?:Group] { par = p; }
        if par is None { break; }
        if par.gid in seen { break; }
        seen[par.gid] = True;
        out.append(par.gid);
        cur = par;
    }
    return sorted(out);
}

test "descendants multiset" {
    g = load_groups([("root", None), ("fleet", "root"), ("team_a", "fleet"), ("team_b", "fleet"), ("pod", "team_a")]);
    assert descendant_ids(g, "fleet") == ["pod", "team_a", "team_b"];
}

test "ancestors chain" {
    g = load_groups([("root", None), ("fleet", "root"), ("pod", "fleet")]);
    assert ancestor_ids(g, "pod") == ["fleet", "root"];
}

test "diamond descendants once per group" {
    g = load_groups([("hub", None), ("left", "hub"), ("right", "hub"), ("join", "left"), ("join2", "right")]);
    assert descendant_ids(g, "hub") == ["join", "join2", "left", "right"];
}

test "unknown group tolerant" {
    g = load_groups([("only", None)]);
    assert descendant_ids(g, "missing") == [];
}
