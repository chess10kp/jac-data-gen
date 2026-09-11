node Anchor { has name: str = "project"; }
node Callable {
    has cid: str;
    has ver: int = 1;
    has result: str = "unknown";
    has effects: str = "pure";
    has boundary: str = "exact";
    has place_fact: str = "none";
}
edge Calls {}
edge SummaryRef {}

walker CollectReachable {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has bound: int = 5;
    has depth: dict[str, int] = {};
    can step_a with Callable entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        cur: int = 0;
        if here.cid in self.depth { cur = self.depth[here.cid] as int; }
        if cur >= self.bound { print(here.cid); return; }
        kids: list[Callable] = [here ->:Calls:->][?:Callable];
        if len(kids) == 0 { print(here.cid); return; }
        for nxt in kids {
            if nxt.cid not in self.depth { self.depth[nxt.cid] = cur + 1; }
            visit :0: [nxt];
        }
        print(here.cid);
    }
    can step_b with Anchor entry {
        if "anchor" in self.claimed { skip; }
        self.claimed["anchor"] = True;
        kids: list[Callable] = [here ->:Calls:->][?:Callable];
        for k in kids { visit :0: [k]; }
        print(here.name);
    }
}

walker CollectCallers {
    has claimed: dict[str, bool] = {};
    has target: str = "";
    has found: list[str] = [];
    can rev_a with Callable entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid != self.target { self.found.append(here.cid); }
        callers: list[Callable] = [here <-:Calls-<-][?:Callable];
        for c in callers { visit :0: [c]; }
        print(here.cid);
    }
}

def new_project(name: str) -> Anchor {
    a = Anchor(name=name);
    return a;
}

def register_callable(graph_root: Anchor, cid: str, ver: int, result: str, effects: str, boundary: str) -> Callable {
    c = Callable(cid=cid, ver=ver, result=result, effects=effects, boundary=boundary);
    graph_root +>:Calls:+> c;
    return c;
}

def add_call_edge(caller: Callable, callee: Callable) -> None {
    caller +>:Calls:+> callee;
    return;
}

def anchor_callable(graph_root: Anchor, c: Callable) -> None {
    graph_root +>:Calls:+> c;
    return;
}

def build_summary(target: Callable) -> dict[str, str] {
    out: dict[str, str] = {};
    out["cid"] = target.cid;
    out["ver"] = str(target.ver);
    out["result"] = target.result;
    out["effects"] = target.effects;
    out["boundary"] = target.boundary;
    out["place_fact"] = target.place_fact;
    return out;
}

def compose_at_callsite(caller: Callable, callee: Callable) -> dict[str, str] {
    # compose exact current facts across admitted edge without provider scans
    res: dict[str, str] = {};
    res["caller"] = caller.cid;
    res["callee"] = callee.cid;
    if callee.boundary == "dynamic" {
        res["result"] = "conservative";
        res["effects"] = "conservative";
        res["boundary"] = "refused";
        return res;
    }
    res["result"] = callee.result;
    if caller.effects == "pure" {
        res["effects"] = callee.effects;
    } else {
        res["effects"] = caller.effects + "+" + callee.effects;
    }
    res["boundary"] = callee.boundary;
    return res;
}

def bounded_closure(entry: Callable, bound: int) -> list[str] {
    d: dict[str, int] = {};
    d[entry.cid] = 0;
    w = entry spawn CollectReachable(bound=bound, depth=d);
    out: list[str] = w.found;
    return out;
}

def stale_after_change(changed: Callable) -> list[str] {
    w = changed spawn CollectCallers(target=changed.cid);
    out: list[str] = w.found;
    return out;
}

with entry {
    demo_root = Anchor(name="demo");
    root ++> demo_root;
    a = Callable(cid="main", ver=1, result="int", effects="pure", boundary="exact");
    b = Callable(cid="util", ver=2, result="str", effects="pure", boundary="exact");
    demo_root +>:Calls:+> a;
    demo_root +>:Calls:+> b;
    a +>:Calls:+> b;
    d: dict[str, int] = {};
    d[a.cid] = 0;
    w1 = a spawn CollectReachable(bound=2, depth=d);
    print(w1.found);
    w2 = b spawn CollectCallers(target=b.cid);
    print(w2.found);
    root spawn CollectReachable(bound=1);
}
