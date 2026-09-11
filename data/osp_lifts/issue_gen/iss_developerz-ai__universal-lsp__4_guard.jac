"""Guard: developerz-ai/universal-lsp#4."""

obj GraphLite { has stamp: int = 0; }

node Module { has nid: str; has label: str; }
node File { has nid: str; has label: str; }
node Symbol { has nid: str; has label: str; }
edge Link {}

def _kind(n: Module | File | Symbol) -> str {
    if isinstance(n, Module) { return "module"; }
    if isinstance(n, File) { return "file"; }
    return "symbol";
}

def _find(nid: str) -> Module | File | Symbol | None {
    for n in [-->][?:Module] { if n.nid == nid { return n; } }
    for n in [-->][?:File] { if n.nid == nid { return n; } }
    for n in [-->][?:Symbol] { if n.nid == nid { return n; } }
    return None;
}

def load_graph(
    nodes: list[tuple[str, str, str]],
    edges: list[tuple[str, str]],
) -> GraphLite {
    mp: dict[str, Module | File | Symbol] = {};
    for (nid, kind, label) in nodes {
        if kind == "module" {
            nd = Module(nid=nid, label=label);
        } elif kind == "file" {
            nd = File(nid=nid, label=label);
        } else {
            nd = Symbol(nid=nid, label=label);
        }
        root ++> nd;
        mp[nid] = nd;
    }
    for (src, tgt) in edges {
        a = mp.get(src, None);
        b = mp.get(tgt, None);
        if a is not None and b is not None { a +>:Link:+> b; }
    }
    return GraphLite(stamp=1);
}

walker BfsTyped {
    has want: str = "";
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can step with Module | File | Symbol entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        if _kind(here) == self.want { self.hits.append(here.nid); }
        visit [->:Link:->] else { disengage; };
    }
}

walker DfsTyped {
    has want: str = "";
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can step with Module | File | Symbol entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        if _kind(here) == self.want { self.hits.append(here.nid); }
        visit :0: [->:Link:->] else { disengage; };
    }
}

def bfs_typed(g: GraphLite, start: str, want: str) -> list[str] {
    _ = g;
    anchor = _find(start);
    if anchor is None { return []; }
    w = anchor spawn BfsTyped(want=want, claimed={}, hits=[]);
    return sorted(w.hits);
}

def dfs_typed(g: GraphLite, start: str, want: str) -> list[str] {
    _ = g;
    anchor = _find(start);
    if anchor is None { return []; }
    w = anchor spawn DfsTyped(want=want, claimed={}, hits=[]);
    return sorted(w.hits);
}

test "typed bfs and dfs on module graph" {
    g = load_graph(
        [
            ("app", "module", "app"),
            ("main", "file", "main.jac"),
            ("util", "file", "util.jac"),
            ("foo", "symbol", "foo"),
            ("bar", "symbol", "bar"),
            ("baz", "symbol", "baz"),
        ],
        [
            ("app", "main"),
            ("app", "util"),
            ("main", "foo"),
            ("main", "bar"),
            ("util", "bar"),
            ("util", "baz"),
            ("baz", "main"),
        ],
    );
    assert bfs_typed(g, "app", "symbol") == ["bar", "baz", "foo"];
    assert dfs_typed(g, "app", "symbol") == ["bar", "baz", "foo"];
    assert bfs_typed(g, "app", "file") == ["main", "util"];
    assert bfs_typed(g, "app", "module") == ["app"];
}

test "diamond adversarial revisit before deeper first visit" {
    g = load_graph(
        [
            ("hub", "module", "hub"),
            ("left", "file", "left"),
            ("right", "file", "right"),
            ("mid", "file", "mid"),
            ("target", "symbol", "target"),
        ],
        [
            ("hub", "left"),
            ("hub", "right"),
            ("left", "mid"),
            ("mid", "right"),
            ("left", "target"),
            ("right", "target"),
            ("target", "left"),
        ],
    );
    assert bfs_typed(g, "hub", "symbol") == ["target"];
    assert dfs_typed(g, "hub", "symbol") == ["target"];
    assert bfs_typed(g, "hub", "file") == ["left", "mid", "right"];
}

test "unknown start id" {
    g = load_graph([("app", "module", "app")], []);
    assert bfs_typed(g, "ghost", "symbol") == [];
    assert dfs_typed(g, "ghost", "file") == [];
}
