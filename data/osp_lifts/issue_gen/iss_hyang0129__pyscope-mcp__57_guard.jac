"""Call graph shortest chain — hyang0129/pyscope-mcp#57."""

node Symbol {
    has fqn: str;
}

edge Calls {}

node GraphIndex {
    has by_fqn: dict[str, Symbol] = {};
}

def new_index() -> GraphIndex {
    return GraphIndex(by_fqn={});
}

def ensure_symbol(g: GraphIndex, fqn: str) -> Symbol {
    if fqn in g.by_fqn {
        return g.by_fqn[fqn];
    }
    nd = Symbol(fqn=fqn);
    g.by_fqn[fqn] = nd;
    return nd;
}

def add_call(g: GraphIndex, caller: str, callee: str) -> None {
    c_nd = ensure_symbol(g, caller);
    t_nd = ensure_symbol(g, callee);
    c_nd +>:Calls:+> t_nd;
}

walker ChainBfs {
    has src_fqn: str;
    has target_fqn: str;
    has max_d: int;
    has claimed: dict[str, bool] = {};
    has depth: dict[str, int] = {};
    has parent: dict[str, str] = {};
    has found_path: list[str] = [];
    has done: bool = False;

    can step with Symbol entry {
        if here.fqn in self.claimed {
            skip;
        }
        self.claimed[here.fqn] = True;
        cur_d: int = self.depth[here.fqn];
        print("visit " + here.fqn);
        if here.fqn == self.target_fqn {
            cur: str = here.fqn;
            parts: list[str] = [];
            while True {
                parts.append(cur);
                if cur == self.src_fqn {
                    break;
                }
                if cur in self.parent {
                    cur = self.parent[cur];
                } else {
                    break;
                }
            }
            rev: list[str] = [];
            idx: int = len(parts) - 1;
            while idx >= 0 {
                rev.append(parts[idx]);
                idx = idx - 1;
            }
            self.found_path = rev;
            self.done = True;
            print("chain found");
            disengage;
        }
        if cur_d < self.max_d {
            kids: list[Symbol] = [here ->:Calls:->][?:Symbol];
            for kid in kids {
                if kid.fqn not in self.claimed {
                    if kid.fqn not in self.depth {
                        self.depth[kid.fqn] = cur_d + 1;
                        self.parent[kid.fqn] = here.fqn;
                        visit [kid];
                    }
                }
            }
        }
    }
}

def call_chain(
    g: GraphIndex,
    src_fqn: str,
    dst_fqn: str,
    max_depth: int = 6,
) -> tuple[list[str] | None, str | None] {
    if src_fqn not in g.by_fqn {
        return (None, "unknown src: try grep as fallback");
    }
    if dst_fqn not in g.by_fqn {
        return (None, "unknown dst: try grep as fallback");
    }
    if src_fqn == dst_fqn {
        return ([src_fqn], None);
    }
    depth0: dict[str, int] = {};
    depth0[src_fqn] = 0;
    src_nd = g.by_fqn[src_fqn];
    w = src_nd spawn ChainBfs(
        src_fqn=src_fqn,
        target_fqn=dst_fqn,
        max_d=max_depth,
        depth=depth0,
        claimed={},
        parent={},
        found_path=[],
        done=False,
    );
    if w.done {
        return (w.found_path, None);
    }
    return (None, "no path within max_depth: try grep as fallback");
}

test "direct_edge" {
    g = new_index();
    add_call(g, "mod.a", "mod.b");
    (path, reason) = call_chain(g, "mod.a", "mod.b", 6);
    assert path == ["mod.a", "mod.b"];
    assert reason == None;
}

test "multi_hop_shortest" {
    g = new_index();
    add_call(g, "pkg.a", "pkg.b");
    add_call(g, "pkg.b", "pkg.c");
    add_call(g, "pkg.c", "pkg.d");
    (path, reason) = call_chain(g, "pkg.a", "pkg.d", 6);
    assert path == ["pkg.a", "pkg.b", "pkg.c", "pkg.d"];
    assert reason == None;
}

test "diamond_revisit_skips_longer" {
    g = new_index();
    add_call(g, "x.a", "x.b");
    add_call(g, "x.a", "x.c");
    add_call(g, "x.b", "x.t");
    add_call(g, "x.c", "x.b");
    add_call(g, "x.c", "x.t");
    (path, reason) = call_chain(g, "x.a", "x.t", 6);
    assert path == ["x.a", "x.b", "x.t"];
    assert reason == None;
}

test "cycle_no_hang" {
    g = new_index();
    add_call(g, "c.a", "c.b");
    add_call(g, "c.b", "c.c");
    add_call(g, "c.c", "c.a");
    add_call(g, "c.b", "c.t");
    (path, reason) = call_chain(g, "c.a", "c.t", 6);
    assert path == ["c.a", "c.b", "c.t"];
    assert reason == None;
}

test "max_depth_exhausted" {
    g = new_index();
    add_call(g, "d.a", "d.b");
    add_call(g, "d.b", "d.c");
    add_call(g, "d.c", "d.e");
    (path, reason) = call_chain(g, "d.a", "d.e", 2);
    assert path == None;
    assert reason == "no path within max_depth: try grep as fallback";
}

test "unknown_src_tolerance" {
    g = new_index();
    add_call(g, "u.b", "u.c");
    (path, reason) = call_chain(g, "u.missing", "u.c", 6);
    assert path == None;
    assert reason == "unknown src: try grep as fallback";
}
