"""Guard: TheLarkInn/aipm#1531."""

obj CrateGraph { has crates: dict[str, CrateNode] = {}; }
node CrateNode { has name: str; }
edge Depends {}

walker DepHop {
    has claimed: dict[str, bool];
    has next: list[CrateNode] = [];

    can step with CrateNode entry {
        for nxt in [here ->:Depends:->][?:CrateNode] {
            if nxt.name in self.claimed { continue; }
            self.claimed[nxt.name] = True;
            self.next.append(nxt);
        }
    }
}

def load_crates(
    crates: list[str],
    edges: list[tuple[str, str]],
) -> CrateGraph {
    g = CrateGraph(crates={});
    for c in crates {
        n = CrateNode(name=c);
        root ++> n;
        g.crates[c] = n;
    }
    for (src, dst) in edges {
        a = g.crates.get(src, None);
        b = g.crates.get(dst, None);
        if a is not None and b is not None { a +>:Depends:+> b; }
    }
    return g;
}

def transitive_deps(g: CrateGraph, `root: str) -> list[str] {
    anchor = g.crates.get(`root, None);
    if anchor is None { return []; }
    claimed: dict[str, bool] = {`root: True};
    reached: list[str] = [`root];
    frontier: list[CrateNode] = [anchor];
    while len(frontier) > 0 {
        nxt: list[CrateNode] = [];
        for f in frontier {
            w = f spawn DepHop(claimed=claimed, next=nxt);
            nxt = w.next;
        }
        for n in nxt { reached.append(n.name); }
        frontier = nxt;
    }
    return sorted(reached);
}

def on_critical_path(g: CrateGraph, roots: list[str], target: str) -> bool {
    if g.crates.get(target, None) is None { return False; }
    for r in roots {
        reach: dict[str, bool] = {};
        for d in transitive_deps(g, r) { reach[d] = True; }
        if target in reach { return True; }
    }
    return False;
}

test "workspace transitive deps" {
    g = load_crates(
        ["workspace", "syn", "jsonschema", "reqwest", "aws-lc-sys"],
        [
            ("workspace", "jsonschema"),
            ("jsonschema", "reqwest"),
            ("reqwest", "aws-lc-sys"),
            ("workspace", "syn"),
        ],
    );
    assert transitive_deps(g, "workspace") == [
        "aws-lc-sys", "jsonschema", "reqwest", "syn", "workspace"
    ];
    assert on_critical_path(g, ["workspace"], "aws-lc-sys") is True;
}

test "cycle keeps leaf" {
    g = load_crates(
        ["a", "b", "c", "leaf"],
        [("a", "b"), ("b", "c"), ("c", "a"), ("c", "leaf")],
    );
    assert transitive_deps(g, "a") == ["a", "b", "c", "leaf"];
}

test "diamond adversarial" {
    g = load_crates(
        ["root", "left", "right", "sink"],
        [("root", "left"), ("root", "right"), ("left", "sink"), ("right", "sink")],
    );
    assert transitive_deps(g, "root") == ["left", "right", "root", "sink"];
}

test "unknown root and target" {
    g = load_crates(["solo"], []);
    assert transitive_deps(g, "ghost") == [];
    assert on_critical_path(g, ["workspace"], "missing") is False;
}
