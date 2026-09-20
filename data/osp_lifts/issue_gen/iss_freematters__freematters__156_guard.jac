"""freematters/freematters#156 — PATH-shadowed fflow hook recursion."""

node Launcher {
    has cid: str;
    has name: str;
    has rank: int = 0;
    has target: str = "";
}

edge Delegate {}

walker TraceWalker {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];

    can step with Launcher entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.out.append(here.cid);
        print("trace", here.cid);
        nxt: list[Launcher] = [];
        for ch in [here ->:Delegate:->][?:Launcher] {
            nxt.append(ch);
        }
        if nxt {
            visit :0: nxt;
        } else {
            disengage;
        }
    }
}

walker LoopWalker {
    has claimed: dict[str, bool] = {};
    has loop: bool = False;

    can probe with Launcher entry {
        if here.cid in self.claimed {
            self.loop = True;
            print("loop", here.cid);
            skip;
        }
        self.claimed[here.cid] = True;
        print("probe", here.cid);
        nxt: list[Launcher] = [];
        for ch in [here ->:Delegate:->][?:Launcher] {
            nxt.append(ch);
        }
        if nxt {
            visit :0: nxt;
        } else {
            disengage;
        }
    }
}

def make_launcher(cid: str, name: str, rank: int, target: str) -> Launcher {
    return Launcher(cid=cid, name=name, rank=rank, target=target);
}

def index_launchers(nodes: list[Launcher]) -> dict[str, Launcher] {
    idx: dict[str, Launcher] = {};
    for nd in nodes {
        idx[nd.cid] = nd;
    }
    return idx;
}

def attach_delegate(src: Launcher, dst: Launcher) {
    src +>:Delegate:+> dst;
}

def resolve_path(order: list[str], name: str, nodes: list[Launcher]) -> str {
    idx: dict[str, Launcher] = index_launchers(nodes);
    for cid in order {
        if cid not in idx {
            continue;
        }
        nd = idx[cid];
        if nd.name == name {
            return nd.cid;
        }
    }
    return "";
}

def trace_delegation_chain(start: Launcher) -> list[str] {
    w = start spawn TraceWalker(claimed={});
    return w.out;
}

def has_recursive_resolution(start: Launcher) -> bool {
    w = start spawn LoopWalker(claimed={});
    return w.loop;
}

def estimate_process_footprint(start: Launcher, steps: int) -> int {
    if has_recursive_resolution(start) {
        return steps * 2;
    }
    tr: list[str] = trace_delegation_chain(start);
    return len(tr);
}

def build_shadow_fixture -> Launcher {
    wrap = make_launcher("wrap", "fflow", 0, "npm");
    glob_node = make_launcher("glob", "fflow", 1, "");
    npm = make_launcher("npm", "npm_exec", 2, "sh");
    sh = make_launcher("sh", "sh_c", 3, "fflow");
    root ++> wrap;
    root ++> glob_node;
    root ++> npm;
    root ++> sh;
    attach_delegate(wrap, npm);
    attach_delegate(npm, sh);
    attach_delegate(sh, wrap);
    return wrap;
}

"""freematters/freematters#156 — PATH-shadowed fflow hook recursion."""

node Launcher {
    has cid: str;
    has name: str;
    has rank: int = 0;
    has target: str = "";
}

edge Delegate {}

walker TraceWalker {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];

    can step with Launcher entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.out.append(here.cid);
        print("trace", here.cid);
        nxt: list[Launcher] = [];
        for ch in [here ->:Delegate:->][?:Launcher] {
            nxt.append(ch);
        }
        if nxt {
            visit :0: nxt;
        } else {
            disengage;
        }
    }
}

walker LoopWalker {
    has claimed: dict[str, bool] = {};
    has loop: bool = False;

    can probe with Launcher entry {
        if here.cid in self.claimed {
            self.loop = True;
            print("loop", here.cid);
            skip;
        }
        self.claimed[here.cid] = True;
        print("probe", here.cid);
        nxt: list[Launcher] = [];
        for ch in [here ->:Delegate:->][?:Launcher] {
            nxt.append(ch);
        }
        if nxt {
            visit :0: nxt;
        } else {
            disengage;
        }
    }
}

def make_launcher(cid: str, name: str, rank: int, target: str) -> Launcher {
    return Launcher(cid=cid, name=name, rank=rank, target=target);
}

def index_launchers(nodes: list[Launcher]) -> dict[str, Launcher] {
    idx: dict[str, Launcher] = {};
    for nd in nodes {
        idx[nd.cid] = nd;
    }
    return idx;
}

def attach_delegate(src: Launcher, dst: Launcher) {
    src +>:Delegate:+> dst;
}

def resolve_path(order: list[str], name: str, nodes: list[Launcher]) -> str {
    idx: dict[str, Launcher] = index_launchers(nodes);
    for cid in order {
        if cid not in idx {
            continue;
        }
        nd = idx[cid];
        if nd.name == name {
            return nd.cid;
        }
    }
    return "";
}

def trace_delegation_chain(start: Launcher) -> list[str] {
    w = start spawn TraceWalker(claimed={});
    return w.out;
}

def has_recursive_resolution(start: Launcher) -> bool {
    w = start spawn LoopWalker(claimed={});
    return w.loop;
}

def estimate_process_footprint(start: Launcher, steps: int) -> int {
    if has_recursive_resolution(start) {
        return steps * 2;
    }
    tr: list[str] = trace_delegation_chain(start);
    return len(tr);
}

def build_shadow_fixture -> Launcher {
    wrap = make_launcher("wrap", "fflow", 0, "npm");
    glob_node = make_launcher("glob", "fflow", 1, "");
    npm = make_launcher("npm", "npm_exec", 2, "sh");
    sh = make_launcher("sh", "sh_c", 3, "fflow");
    root ++> wrap;
    root ++> glob_node;
    root ++> npm;
    root ++> sh;
    attach_delegate(wrap, npm);
    attach_delegate(npm, sh);
    attach_delegate(sh, wrap);
    return wrap;
}

test "shadow_fixture_has_delegate_cycle" {
    start = build_shadow_fixture();
    assert has_recursive_resolution(start);
}

test "trace_delegation_chain_once_only" {
    start = build_shadow_fixture();
    chain = trace_delegation_chain(start);
    assert chain == ["wrap", "npm", "sh"];
}

test "resolve_path_prefers_first_shadow_match" {
    start = build_shadow_fixture();
    nodes: list[Launcher] = [];
    for nd in [root -->][?:Launcher] {
        nodes.append(nd);
    }
    order: list[str] = ["wrap", "glob", "npm", "sh"];
    assert resolve_path(order, "fflow", nodes) == "wrap";
}

test "resolve_path_later_rank_wins_when_first" {
    a = make_launcher("wrap", "fflow", 0, "npm");
    b = make_launcher("glob", "fflow", 1, "");
    nodes: list[Launcher] = [a, b];
    order: list[str] = ["glob", "wrap"];
    assert resolve_path(order, "fflow", nodes) == "glob";
}

test "resolve_path_unknown_name_empty" {
    start = build_shadow_fixture();
    nodes: list[Launcher] = [];
    for nd in [root -->][?:Launcher] {
        nodes.append(nd);
    }
    order: list[str] = ["wrap", "glob", "npm", "sh"];
    assert resolve_path(order, "missing", nodes) == "";
}

test "estimate_process_footprint_amplifies_on_loop" {
    start = build_shadow_fixture();
    assert estimate_process_footprint(start, 4000) == 8000;
}
