"""gastownhall/gascity#2903 — idle open-bead stability via dependency closure (OSP lift)."""

obj BeadStore {
    has bead_status: dict[str, str] = {};
    has bead_tier: dict[str, str] = {};
}

node Bead {
    has bead_id: str;
    has status: str;
    has tier: str;
}

edge Depends {
    has kind: str;
}

walker DepCloseWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has origin: str = "";

    can step with Bead entry {
        if here.bead_id in self.claimed { skip; }
        self.claimed[here.bead_id] = True;
        if here.bead_id != self.origin { self.reached.append(here.bead_id); }
        visit [->:Depends:->] else { disengage; };
    }
}

def _find(bead_id: str) -> Bead | None {
    for n in [-->][?:Bead] {
        if n.bead_id == bead_id { return n; }
    }
    return None;
}

def load_bead_graph(
    bead_status: dict[str, str],
    bead_tier: dict[str, str],
    edges: list[tuple[str, str, str]],
) -> BeadStore {
    mp: dict[str, Bead] = {};
    for bid in bead_status {
        fresh = Bead(
            bead_id=bid,
            status=bead_status[bid],
            tier=bead_tier.get(bid, "issue"),
        );
        root ++> fresh;
        mp[bid] = fresh;
    }
    for (src, dst, kind) in edges {
        a = mp.get(src, None);
        b = mp.get(dst, None);
        if a is not None and b is not None { a +>:Depends(kind=kind):+> b; }
    }
    return BeadStore(bead_status=bead_status, bead_tier=bead_tier);
}

def dependency_closure(store: BeadStore, bead_id: str) -> list[str] {
    if bead_id not in store.bead_status { return []; }
    anchor = _find(bead_id);
    if anchor is None { return []; }
    w = anchor spawn DepCloseWalk(claimed={}, reached=[], origin=bead_id);
    return sorted(w.reached);
}

def protected_from_reap(store: BeadStore, target_id: str) -> bool {
    if target_id not in store.bead_status { return False; }
    if store.bead_status.get(target_id, "") != "closed" { return False; }
    for (bid, status) in store.bead_status.items() {
        if status != "open" { continue; }
        if store.bead_tier.get(bid, "issue") != "wisp" { continue; }
        if target_id in dependency_closure(store, bid) { return True; }
    }
    return False;
}

def idle_open_counts(store: BeadStore) -> tuple[int, int] {
    issues = 0;
    wisps = 0;
    for (bid, status) in store.bead_status.items() {
        if status != "open" { continue; }
        if store.bead_tier.get(bid, "issue") == "wisp" { wisps += 1; }
        else { issues += 1; }
    }
    return (issues, wisps);
}
