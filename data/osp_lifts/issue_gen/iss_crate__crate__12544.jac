"""OSP lift for crate/crate#12544 — recursive CTE."""

node Row {
    has key: str;
}

edge CteEdge {}

walker CteWalker {
    has order: list[str] = [];
    has claimed: dict[str, bool] = {};
    has start: str = "";

    can begin with Root entry {
        for r in [-->][?:Row] {
            if r.key == self.start {
                visit [r];
            }
        }
    }

    can step with Row entry {
        if here.key in self.claimed {
            skip;
        }
        self.claimed[here.key] = True;
        self.order.append(here.key);
        visit [-->];
    }

    can finish with Root exit {
        report self.order;
    }
}

def _wire(edges: list[tuple[str, str]]) -> None {
    nodes: dict[str, Row] = {};
    for (a, b) in edges {
        if a not in nodes {
            nodes[a] = Row(key=a);
            root ++> nodes[a];
        }
        if b not in nodes {
            nodes[b] = Row(key=b);
            root ++> nodes[b];
        }
        nodes[a] +>:CteEdge:+> nodes[b];
    }
}

def recursive_cte_expand(
    seed: str,
    edges: list[tuple[str, str]],
) -> list[str] {
    _wire(edges);
    w = root spawn CteWalker(start=seed);
    return w.reports[0] if w.reports else [];
}

def cte_reachable(seed: str, edges: list[tuple[str, str]]) -> list[str] {
    got = recursive_cte_expand(seed, edges);
    seen: set[str] = set();
    for k in got {
        seen.add(k);
    }
    return sorted(seen);
}

def is_recursive_safe(edges: list[tuple[str, str]]) -> bool {
    adj: dict[str, list[str]] = {};
    nodes: set[str] = set();
    for (a, b) in edges {
        nodes.add(a);
        nodes.add(b);
        if a not in adj {
            adj[a] = [];
        }
        adj[a].append(b);
    }
    color: dict[str, int] = {};

    def dfs(n: str) -> bool {
        color[n] = 1;
        for c in adj.get(n, []) {
            st = color.get(c, 0);
            if st == 1 {
                return False;
            }
            if st == 0 and not dfs(c) {
                return False;
            }
        }
        color[n] = 2;
        return True;
    }

    for n in nodes {
        if color.get(n, 0) == 0 and not dfs(n) {
            return False;
        }
    }
    return True;
}
