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
