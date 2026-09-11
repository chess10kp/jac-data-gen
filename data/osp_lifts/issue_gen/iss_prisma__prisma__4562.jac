"""OSP lift for prisma/prisma#4562 — tree structures."""

node TreeNode {
    has name: str;
}

edge Child {}

walker ClosureWalker {
    has names: list[str] = [];
    has claimed: dict[str, bool] = {};
    has start: str = "";

    can begin with Root entry {
        for n in [-->][?:TreeNode] {
            if n.name == self.start {
                visit [n];
            }
        }
    }

    can step with TreeNode entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.names.append(here.name);
        visit [-->];
    }

    can finish with Root exit {
        report sorted(self.names);
    }
}

def _wire(edges: list[tuple[str, str]]) -> dict[str, list[str]] {
    nodes: dict[str, TreeNode] = {};
    kids: dict[str, list[str]] = {};
    for (p, c) in edges {
        if p not in nodes {
            nodes[p] = TreeNode(name=p);
            root ++> nodes[p];
        }
        if c not in nodes {
            nodes[c] = TreeNode(name=c);
            root ++> nodes[c];
        }
        nodes[p] +>:Child:+> nodes[c];
        if p not in kids {
            kids[p] = [];
        }
        kids[p].append(c);
    }
    return kids;
}

def children_of(node: str, edges: list[tuple[str, str]]) -> list[str] {
    kids = _wire(edges);
    return sorted(kids.get(node, []));
}

def ancestors(node: str, edges: list[tuple[str, str]]) -> list[str] {
    parent: dict[str, str] = {};
    for (p, c) in edges {
        parent[c] = p;
    }
    chain: list[str] = [];
    cur = node;
    while cur in parent {
        cur = parent[cur];
        chain.append(cur);
    }
    return chain;
}

def is_acyclic(edges: list[tuple[str, str]]) -> bool {
    kids = _wire(edges);
    color: dict[str, int] = {};

    def dfs(n: str) -> bool {
        color[n] = 1;
        for c in kids.get(n, []) {
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

    for n in kids {
        if color.get(n, 0) == 0 and not dfs(n) {
            return False;
        }
    }
    return True;
}

def tree_closure(root_name: str, edges: list[tuple[str, str]]) -> list[str] {
    _wire(edges);
    w = root spawn ClosureWalker(start=root_name);
    return w.reports[0] if w.reports else [];
}
