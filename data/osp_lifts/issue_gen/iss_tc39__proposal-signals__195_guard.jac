"""tc39/proposal-signals#195 — watcher.track like computeds mirror of untrack."""
node State { has sid: str; has value: int = 0; }
node Computed { has cid: str; has value: int = 0; has dirty: bool = False; }
node Watcher { has wid: str; has watched: list[str] = []; }

edge Depends {}
edge Watches {}

walker GatherWatcherStates {
    has claimed: dict[str, bool] = {};
    has states: list[State] = [];
    can step_watcher with Watcher entry {
        if here.wid in self.claimed { skip; }
        self.claimed[here.wid] = True;
        print("visit watcher " + here.wid);
        for s in [here ->:Watches:->][?:State] {
            visit :0: [s];
        }
        for c in [here ->:Watches:->][?:Computed] {
            visit :0: [c];
        }
    }
    can step_computed with Computed entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("visit computed " + here.cid);
        kids_s: list[State] = [here ->:Depends:->][?:State];
        kids_c: list[Computed] = [here ->:Depends:->][?:Computed];
        for ks in kids_s { visit :0: [ks]; }
        for kc in kids_c { visit :0: [kc]; }
    }
    can step_state with State entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        print("visit state " + here.sid);
        self.states.append(here);
    }
}

walker ClosureWalk {
    has claimed: dict[str, bool] = {};
    has ids: list[str] = [];
    can c_state with State entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        print("closure state " + here.sid);
        self.ids.append(here.sid);
    }
    can c_computed with Computed entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("closure computed " + here.cid);
        self.ids.append(here.cid);
        cs: list[State] = [here ->:Depends:->][?:State];
        cc: list[Computed] = [here ->:Depends:->][?:Computed];
        for x in cs { visit :0: [x]; }
        for y in cc { visit :0: [y]; }
    }
    can c_watcher with Watcher entry {
        if here.wid in self.claimed { skip; }
        self.claimed[here.wid] = True;
        print("closure watcher " + here.wid);
        ws: list[State] = [here ->:Watches:->][?:State];
        wc: list[Computed] = [here ->:Watches:->][?:Computed];
        for a in ws { visit :0: [a]; }
        for b in wc { visit :0: [b]; }
    }
}

def make_state(sid: str, value: int) -> State {
    # create State and anchor to root
    nd: State = State(sid=sid, value=value);
    root ++> nd;
    return nd;
}
def make_computed(cid: str, value: int) -> Computed {
    nd: Computed = Computed(cid=cid, value=value);
    root ++> nd;
    return nd;
}
def make_watcher(wid: str) -> Watcher {
    nd: Watcher = Watcher(wid=wid);
    root ++> nd;
    return nd;
}
def add_depends(parent: Computed, dep: State) -> None {
    parent +>:Depends:+> dep;
}
def add_depends_computed(parent: Computed, child: Computed) -> None {
    parent +>:Depends:+> child;
}
def watcher_watch(w: Watcher, s: State) -> None {
    # record in list and graph edge
    if s.sid not in w.watched { w.watched.append(s.sid); }
    w +>:Watches:+> s;
}
def watcher_watch_computed(w: Watcher, c: Computed) -> None {
    w +>:Watches:+> c;
}
def get_watched_ids(w: Watcher) -> list[str] {
    # two-phase: collect via walker (claimed dedup) then return list field filtered
    # walker confirms graph closure without duplicates
    gw: GatherWatcherStates = w spawn GatherWatcherStates(claimed={}, states=[]);
    # result outside walk: return field copy to avoid aliasing
    out: list[str] = [];
    for sid in w.watched { out.append(sid); }
    return out;
}
def get_closure_ids(start: Watcher) -> list[str] {
    cw: ClosureWalk = start spawn ClosureWalk(claimed={}, ids=[]);
    res: list[str] = [];
    for i in cw.ids { res.append(i); }
    return res;
}
def watcher_track(w: Watcher, accessed: list[State] | None = None) -> list[str] {
    # mirrors spec: save set, clear, repopulate with body accesses, add-before-remove
    acc: list[State] = [];
    if accessed is not None { acc = accessed; }
    saved: list[str] = [];
    for s in w.watched { saved.append(s); }
    # speculative clear
    w.watched = [];
    seen: dict[str, bool] = {};
    new_ids: list[str] = [];
    for st in acc {
        if st.sid in seen { continue; }
        seen[st.sid] = True;
        new_ids.append(st.sid);
    }
    # add phase: create edges for new signals not in saved
    for st in acc {
        in_saved: bool = False;
        for old in saved { if old == st.sid { in_saved = True; } }
        if not in_saved {
            w +>:Watches:+> st;
        }
    }
    # collect mutation outside walk: just set field
    w.watched = new_ids;
    return w.watched;
}
def watcher_reset(w: Watcher) -> list[str] {
    # equivalent to watcher.track(() => {})
    empty: list[State] = [];
    return watcher_track(w, empty);
}
def collect_states_for_computed(c: Computed) -> list[str] {
    cw: ClosureWalk = c spawn ClosureWalk(claimed={}, ids=[]);
    out: list[str] = [];
    for x in cw.ids { out.append(x); }
    return out;
}

with entry {
    nd: State = State(sid="demo", value=1);
    root ++> nd;
    w: Watcher = Watcher(wid="demo_w");
    root ++> w;
    g: GatherWatcherStates = w spawn GatherWatcherStates(claimed={}, states=[]);
    print("demo entry states " + str(len(g.states)));
}

test "diamond revisit adversarial" {
    s1 = make_state("s1", 1);
    s2 = make_state("s2", 2);
    s3 = make_state("s3", 3);
    s4 = make_state("s4", 4);
    c1 = make_computed("c1", 10);
    c2 = make_computed("c2", 20);
    c3 = make_computed("c3", 30);
    # diamond: c1 depends s1,s2 ; c2 depends s1,s3 ; c3 depends c1,c2
    add_depends(c1, s1); add_depends(c1, s2);
    add_depends(c2, s1); add_depends(c2, s3);
    add_depends_computed(c3, c1); add_depends_computed(c3, c2);
    w = make_watcher("w_diamond");
    watcher_watch(w, s1); watcher_watch(w, s2);
    # closure via walker should dedup s1 visited twice
    ids = collect_states_for_computed(c3);
    assert(sorted(ids) == ["c1", "c2", "c3", "s1", "s2", "s3"]);;
    # watcher closure also dedups
    w2 = make_watcher("w2");
    w2 +>:Watches:+> c3;
    cids = get_closure_ids(w2);
    assert("s1" in cids);;
    assert(len(cids) == 6);;
}

test "watcher track diff add before remove" {
    a = make_state("a", 1);
    b = make_state("b", 2);
    c = make_state("c", 3);
    w = make_watcher("w_track");
    watcher_watch(w, a); watcher_watch(w, b);
    assert(sorted(get_watched_ids(w)) == ["a", "b"]);;
    # track body accesses b,c => should remove a, keep b, add c
    nxt: list[State] = []; nxt.append(b); nxt.append(c);
    watcher_track(w, nxt);
    assert(sorted(get_watched_ids(w)) == ["b", "c"]);;
    # revisit with same set preserves order dedup
    dup: list[State] = []; dup.append(c); dup.append(c); dup.append(b);
    watcher_track(w, dup);
    got = get_watched_ids(w);
    assert(len(got) == 2);;
    assert(sorted(got) == ["b", "c"]);;
}

test "watcher reset clears and unknown tolerance" {
    x = make_state("x", 5);
    y = make_state("y", 6);
    w = make_watcher("w_reset");
    watcher_watch(w, x); watcher_watch(w, y);
    watcher_reset(w);
    assert(get_watched_ids(w) == []);;
    # second reset idempotent
    watcher_reset(w);
    assert(get_watched_ids(w) == []);;
    # unknown watcher not in graph still returns empty without throw
    w2 = Watcher(wid="ghost");
    # not anchored, still tolerance
    assert(get_watched_ids(w2) == []);;
    assert(watcher_reset(w2) == []);;
}

test "cycle via computed depends handles skip" {
    s = make_state("sc", 1);
    ca = make_computed("ca", 1);
    cb = make_computed("cb", 2);
    add_depends(ca, s);
    add_depends_computed(ca, cb);
    add_depends_computed(cb, ca);
    # should not loop infinitely, claim-map skips revisit
    ids = collect_states_for_computed(ca);
    assert("sc" in ids);;
    assert("ca" in ids);;
    assert("cb" in ids);;
    assert(len(ids) == 3);;
}

test "watcher track empty body like untrack" {
    p = make_state("p", 1);
    w = make_watcher("w_empty");
    watcher_watch(w, p);
    assert(get_watched_ids(w) == ["p"]);;
    emp: list[State] = [];
    watcher_track(w, emp);
    assert(get_watched_ids(w) == []);;
    # add again then track with single
    watcher_track(w, [p]);
    assert(get_watched_ids(w) == ["p"]);;
}
