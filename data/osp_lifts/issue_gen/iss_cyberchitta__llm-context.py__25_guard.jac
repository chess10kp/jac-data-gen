"""cyberchitta/llm-context.py#25 — Rule-driven context lacks import-graph expansion."""

node ContextFile {
    has path: str;
    has kind: str;
    has weight_kb: float = 0.0;
}

edge Imports {}

walker TransitiveImportsWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with ContextFile entry {
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        if here.path != self.origin {
            self.found.append(here.path);
        }
        kids = [here ->:Imports:->][?:ContextFile];
        nms: list[str] = [];
        for n in kids { nms.append(n.path); }
        for nm in sorted(nms) {
            for n in kids {
                if n.path == nm {
                    n spawn TransitiveImportsWalk(
                        claimed=self.claimed,
                        found=self.found,
                        origin=self.origin,
                    );
                }
            }
        }
    }
}

walker ImportPathWalk {
    has target: str = "";
    has max_depth: int = 12;
    has trail: list[str] = [];
    has paths: list[list[str]] = [];

    can step with ContextFile entry {
        if here.path in self.trail { skip; }
        nt: list[str] = [];
        for x in self.trail { nt.append(x); }
        nt.append(here.path);
        if len(nt) > self.max_depth { skip; }
        if here.path == self.target {
            row: list[str] = [];
            for x in nt { row.append(x); }
            self.paths.append(row);
            skip;
        }
        if len(nt) >= self.max_depth { skip; }
        kids = [here ->:Imports:->][?:ContextFile];
        nms: list[str] = [];
        for n in kids { nms.append(n.path); }
        for nm in sorted(nms) {
            for n in kids {
                if n.path == nm {
                    n spawn ImportPathWalk(
                        target=self.target,
                        max_depth=self.max_depth,
                        trail=nt,
                        paths=self.paths,
                    );
                }
            }
        }
    }
}

obj ContextGraph {
    has kb: dict[str, float] = {};
    has kind: dict[str, str] = {};
    has imports: dict[str, list[str]] = {};
    has files: dict[str, ContextFile] = {};

    def add_file(path: str, kind: str, weight_kb: float) {
        self.kb[path] = weight_kb;
        self.kind[path] = kind;
        self.imports.setdefault(path, []);
        if path not in self.files {
            nd = ContextFile(path=path, kind=kind, weight_kb=weight_kb);
            root ++> nd;
            self.files[path] = nd;
        } else {
            f = self.files[path];
            f.kind = kind;
            f.weight_kb = weight_kb;
        }
    }

    def add_import(src: str, dst: str) {
        if src in self.imports and dst in self.kb {
            self.imports[src].append(dst);
            s = self.files.get(src, None);
            d = self.files.get(dst, None);
            if s is not None and d is not None { s +>:Imports:+> d; }
        }
    }
}

def load_context_graph(
    files: list[tuple[str, str, float]],
    edges: list[tuple[str, str]],
) -> ContextGraph {
    g = ContextGraph();
    for (path, kind, weight_kb) in files {
        g.add_file(path, kind, weight_kb);
    }
    for (src, dst) in edges {
        g.add_import(src, dst);
    }
    return g;
}

def transitive_imports(g: ContextGraph, `entry: str) -> list[str] {
    if `entry not in g.kb { return []; }
    nd = g.files.get(`entry, None);
    if nd is None { return []; }
    w = nd spawn TransitiveImportsWalk(claimed={}, found=[], origin=`entry);
    return sorted(w.found);
}

def import_paths(
    g: ContextGraph,
    source: str,
    target: str,
    *,
    max_depth: int = 12,
) -> list[list[str]] {
    if source not in g.kb or target not in g.kb { return []; }
    nd = g.files.get(source, None);
    if nd is None { return []; }
    w = nd spawn ImportPathWalk(
        target=target,
        max_depth=max_depth,
        trail=[],
        paths=[],
    );
    out: list[list[str]] = [];
    for p in w.paths {
        row: list[str] = [];
        for x in p { row.append(x); }
        out.append(row);
    }
    return sorted(out);
}

def impact_by_kind(g: ContextGraph, `entry: str) -> dict[str, list[str]] {
    buckets: dict[str, list[str]] = {};
    for path in transitive_imports(g, `entry) {
        k = g.kind.get(path, "unknown");
        buckets.setdefault(k, []).append(path);
    }
    result: dict[str, list[str]] = {};
    for (k, v) in sorted(buckets.items()) {
        result[k] = sorted(v);
    }
    return result;
}

def preview_token_kb(g: ContextGraph, `entry: str) -> float {
    if `entry not in g.kb { return 0.0; }
    total = g.kb[`entry];
    for path in transitive_imports(g, `entry) {
        total += g.kb[path];
    }
    return total;
}

def rule_context_files(
    g: ContextGraph,
    seeds: list[str],
    *,
    expand_deps: bool = True,
) -> list[str] {
    chosen: dict[str, bool] = {};
    for seed in seeds {
        if seed not in g.kb { continue; }
        chosen[seed] = True;
        if expand_deps {
            for dep in transitive_imports(g, seed) {
                chosen[dep] = True;
            }
        }
    }
    out: list[str] = [];
    for p in chosen.keys() { out.append(p); }
    return sorted(out);
}

test "diamond revisit transitive closure" {
    g = load_context_graph(
        [
            ("root", "ui", 1.0),
            ("right", "render", 2.0),
            ("left", "render", 3.0),
            ("sink", "test", 4.0),
        ],
        [
            ("root", "right"),
            ("right", "sink"),
            ("root", "left"),
            ("left", "sink"),
        ],
    );
    assert transitive_imports(g, "root") == ["left", "right", "sink"];;
    assert preview_token_kb(g, "root") == 10.0;;
}

test "unknown id tolerance" {
    g = load_context_graph([("only", "api", 2.0)], []);
    assert transitive_imports(g, "missing") == [];;
    assert import_paths(g, "only", "ghost") == [];;
    assert import_paths(g, "ghost", "only") == [];;
    assert preview_token_kb(g, "missing") == 0.0;;
    assert impact_by_kind(g, "missing") == {};;
    assert rule_context_files(g, ["ghost", "only"], expand_deps=True) == ["only"];;
    g.add_import("only", "ghost");
    g.add_import("ghost", "only");
    assert transitive_imports(g, "only") == [];;
    assert len(g.imports["only"]) == 0;;
}

test "import paths diamond adversarial order" {
    g = load_context_graph(
        [
            ("a", "ui", 0.0),
            ("b", "render", 0.0),
            ("c", "render", 0.0),
            ("d", "test", 0.0),
        ],
        [
            ("a", "c"),
            ("c", "d"),
            ("a", "b"),
            ("b", "d"),
        ],
    );
    assert import_paths(g, "a", "d") == [["a", "b", "d"], ["a", "c", "d"]];;
}

test "import paths max depth exact boundary" {
    g = load_context_graph(
        [
            ("s", "ui", 0.0),
            ("a", "render", 0.0),
            ("b", "render", 0.0),
            ("t", "test", 0.0),
        ],
        [("s", "a"), ("a", "b"), ("b", "t")],
    );
    assert import_paths(g, "s", "t", max_depth=3) == [];;
    assert import_paths(g, "s", "t", max_depth=4) == [["s", "a", "b", "t"]];;
}

test "ignored import endpoints" {
    g = load_context_graph(
        [("mid", "api", 1.0), ("tail", "api", 2.0)],
        [("missing", "mid"), ("mid", "tail"), ("mid", "ghost")],
    );
    assert transitive_imports(g, "mid") == ["tail"];;
    assert import_paths(g, "mid", "tail") == [["mid", "tail"]];;
    assert preview_token_kb(g, "mid") == 3.0;;
}

test "rule context seeds without expansion" {
    g = load_context_graph(
        [
            ("x", "api", 1.0),
            ("y", "api", 2.0),
            ("z", "test", 3.0),
        ],
        [("x", "y"), ("y", "z")],
    );
    assert rule_context_files(g, ["x", "ghost", "z"], expand_deps=False) == ["x", "z"];;
    assert rule_context_files(g, ["x"], expand_deps=True) == ["x", "y", "z"];;
}
