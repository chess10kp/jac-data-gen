"""0xPlayerOne/cortana#2072 — Bounded code relationship neighborhood."""

node Symbol { has sid: str; }
edge Refs {}

obj CodeGraph {
    has symbols: dict[str, Symbol] = {};
}

walker BoundedWalk {
    has max_depth: int;
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has depth: dict[str, int] = {};

    can step with Symbol entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.reached.append(here.sid);
        cur_depth = self.depth.get(here.sid, 0);
        if cur_depth >= self.max_depth { disengage; }
        for nxt in [here ->:Refs:->][?:Symbol] {
            if not (nxt.sid in self.depth) {
                self.depth[nxt.sid] = cur_depth + 1;
                visit [nxt];
            }
        }
    }
}

def load_code_graph(symbols: list[str], refs: list[tuple[str, str]]) -> CodeGraph {
    g = CodeGraph();
    for sid in symbols {
        nd = Symbol(sid=sid);
        root ++> nd;
        g.symbols[sid] = nd;
    }
    for (src, dst) in refs {
        s = g.symbols.get(src, None);
        d = g.symbols.get(dst, None);
        if s is not None and d is not None { s +>:Refs:+> d; }
    }
    return g;
}

def neighborhood(graph: CodeGraph, seed: str, max_depth: int) -> list[str] {
    nd = graph.symbols.get(seed, None);
    if nd is None or max_depth < 0 { return []; }
    w = nd spawn BoundedWalk(
        max_depth=max_depth,
        claimed={},
        reached=[],
        depth={seed: 0},
    );
    return sorted(w.reached);
}
