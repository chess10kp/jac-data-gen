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
