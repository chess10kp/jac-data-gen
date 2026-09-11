"""OSP lift: governed graph-query evidence. Source: tangpingqingwa/hartevo-desktop#828."""

node GraphVertex {
    has name: str;
}

edge Relates {}

glob DEFAULT_HOP_BUDGET: int = 4;
glob DEFAULT_ROW_CAP: int = 64;

walker GovernedWalker {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has trunc: list[bool] = [False];
    has hop_budget: int = 0;
    has row_cap: int = 0;
    has depth: int = 0;
    has start: str = "";

    can begin with Root entry {
        for v in [-->][?:GraphVertex] {
            if v.name == self.start {
                visit [v];
                return;
            }
        }
    }

    can step with GraphVertex entry {
        if here.name in self.claimed {
            skip;
        }
        if len(self.reached) >= self.row_cap {
            self.trunc[0] = True;
            skip;
        }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        if self.depth >= self.hop_budget {
            disengage;
        }
        for nxt in [here ->:Relates:->][?:GraphVertex] {
            nxt spawn GovernedWalker(
                claimed=self.claimed,
                reached=self.reached,
                trunc=self.trunc,
                hop_budget=self.hop_budget,
                row_cap=self.row_cap,
                depth=self.depth + 1,
                start=self.start,
            );
        }
    }
}

def node_digest(label: str) -> str {
    acc = 0;
    for ch in label {
        acc = (acc * 31 + ord(ch)) & 0xFFFFFFFF;
    }
    return f"d:{acc:08x}";
}

def _wire(edges: list[tuple[str, str]]) -> dict[str, GraphVertex] {
    nodes: dict[str, GraphVertex] = {};
    for (a, b) in edges {
        if a not in nodes {
            nodes[a] = GraphVertex(name=a);
            root ++> nodes[a];
        }
        if b not in nodes {
            nodes[b] = GraphVertex(name=b);
            root ++> nodes[b];
        }
        nodes[a] +>:Relates:+> nodes[b];
    }
    return nodes;
}

def governed_reach(
    start: str,
    edges: list[tuple[str, str]],
    hop_budget: int = DEFAULT_HOP_BUDGET,
    row_cap: int = DEFAULT_ROW_CAP,
) -> tuple[str, list[str]] {
    nodes = _wire(edges);
    if start not in nodes {
        return ("EMPTY", []);
    }
    w = root spawn GovernedWalker(
        start=start,
        claimed={},
        reached=[],
        trunc=[False],
        hop_budget=hop_budget,
        row_cap=row_cap,
        depth=0,
    );
    if not w.reached {
        return ("EMPTY", []);
    }
    status = "PARTIAL" if w.trunc[0] else "PRESENT";
    digests: list[str] = [];
    for name in w.reached {
        digests.append(node_digest(name));
    }
    return (status, sorted(digests));
}

def within_budget(
    start: str,
    edges: list[tuple[str, str]],
    hop_budget: int = DEFAULT_HOP_BUDGET,
    row_cap: int = DEFAULT_ROW_CAP,
) -> bool {
    (status, _) = governed_reach(start, edges, hop_budget, row_cap);
    return status == "PRESENT";
}
