"""OSP lift for markhuangai/dense-mem#244 — guided traversal, hierarchy, rules."""

node Entity {
    has name: str;
}

edge Rel {}
edge IsA {}

walker GuidedWalker {
    has order: list[str] = [];
    has claimed: dict[str, bool] = {};
    has start: str = "";
    has allowed: dict[str, bool] = {};

    can begin with Root entry {
        for e in [-->][?:Entity] {
            if e.name == self.start and e.name in self.allowed {
                visit [e];
            }
        }
    }

    can step with Entity entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.order.append(here.name);
        for nxt in [->:Rel:->][?:Entity] {
            if nxt.name in self.allowed and nxt.name not in self.claimed {
                visit [nxt];
            }
        }
    }

    can finish with Root exit {
        report self.order;
    }
}

walker HierarchyWalker {
    has order: list[str] = [];
    has claimed: dict[str, bool] = {};
    has start: str = "";

    can begin with Root entry {
        for e in [-->][?:Entity] {
            if e.name == self.start {
                visit [e];
            }
        }
    }

    can step with Entity entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.order.append(here.name);
        for par in [->:IsA:->][?:Entity] {
            if par.name not in self.claimed {
                visit [par];
            }
        }
    }

    can finish with Root exit {
        report self.order;
    }
}

def _allowed_map(names: list[str]) -> dict[str, bool] {
    out: dict[str, bool] = {};
    for n in names {
        out[n] = True;
    }
    return out;
}

def _wire_rel(edges: list[tuple[str, str]], start: str) -> None {
    nodes: dict[str, Entity] = {};
    for (a, b) in sorted(edges) {
        if a not in nodes {
            nodes[a] = Entity(name=a);
            root ++> nodes[a];
        }
        if b not in nodes {
            nodes[b] = Entity(name=b);
            root ++> nodes[b];
        }
        nodes[a] +>:Rel:+> nodes[b];
    }
    if start and start not in nodes {
        root ++> Entity(name=start);
    }
}

def _wire_isa(parent_edges: list[tuple[str, str]], class_key: str) -> None {
    nodes: dict[str, Entity] = {};
    for (child, par) in sorted(parent_edges) {
        if child not in nodes {
            nodes[child] = Entity(name=child);
            root ++> nodes[child];
        }
        if par not in nodes {
            nodes[par] = Entity(name=par);
            root ++> nodes[par];
        }
        nodes[child] +>:IsA:+> nodes[par];
    }
    if class_key and class_key not in nodes {
        root ++> Entity(name=class_key);
    }
}

def _hierarchy_is_dag(parent_edges: list[tuple[str, str]]) -> bool {
    adj: dict[str, list[str]] = {};
    nodes: set[str] = set();
    for (c, p) in parent_edges {
        if c not in adj {
            adj[c] = [];
        }
        adj[c].append(p);
        nodes.add(c);
        nodes.add(p);
    }
    color: dict[str, int] = {};
    for n in nodes {
        color[n] = 0;
    }

    def dfs(u: str) -> bool {
        color[u] = 1;
        for v in adj.get(u, []) {
            if color.get(v, 0) == 1 {
                return False;
            }
            if color.get(v, 0) == 0 and not dfs(v) {
                return False;
            }
        }
        color[u] = 2;
        return True;
    }

    for n in nodes {
        if color.get(n, 0) == 0 and not dfs(n) {
            return False;
        }
    }
    return True;
}

def guided_traversal(
    start: str,
    edges: list[tuple[str, str]],
    allowed: set[str],
) -> list[str] {
    if start not in allowed {
        return [];
    }
    _wire_rel(edges, start);
    allow_list: list[str] = [];
    for x in allowed {
        allow_list.append(x);
    }
    w = root spawn GuidedWalker(start=start, allowed=_allowed_map(allow_list));
    return w.reports[0] if w.reports else [start];
}

def hierarchy_closure(`root: str, parent_edges: list[tuple[str, str]]) -> list[str] {
    if not _hierarchy_is_dag(parent_edges) {
        raise ValueError("hierarchy cycle");
    }
    _wire_isa(parent_edges, `root);
    w = root spawn HierarchyWalker(start=`root);
    got = w.reports[0] if w.reports else [];
    if not got {
        return [`root];
    }
    return got;
}

def _bind_one(
    atom: tuple[str, str, str],
    fact: tuple[str, str, str],
    bind: dict[str, str],
) -> dict[str, str] | None {
    s = atom[0];
    p = atom[1];
    o = atom[2];
    fs = fact[0];
    fp = fact[1];
    fo = fact[2];
    if p != fp {
        return None;
    }
    nb = {**bind};
    if s.startswith("?") {
        if s in nb and nb[s] != fs {
            return None;
        }
        nb[s] = fs;
    } elif s != fs {
        return None;
    }
    if o.startswith("?") {
        if o in nb and nb[o] != fo {
            return None;
        }
        nb[o] = fo;
    } elif o != fo {
        return None;
    }
    return nb;
}

def _instantiate(
    atom: tuple[str, str, str], bind: dict[str, str]
) -> tuple[str, str, str] {
    s = atom[0];
    p = atom[1];
    o = atom[2];
    if s.startswith("?") {
        s = bind[s];
    }
    if o.startswith("?") {
        o = bind[o];
    }
    return (s, p, o);
}

def apply_rules(
    facts: list[tuple[str, str, str]],
    rules: list[tuple[list[tuple[str, str, str]], tuple[str, str, str]]],
) -> list[tuple[str, str, str]] {
    derived: list[tuple[str, str, str]] = [];
    for item in rules {
        body = item[0];
        head = item[1];
        if len(body) == 1 {
            for f in facts {
                b = _bind_one(body[0], f, {});
                if b is not None {
                    h = _instantiate(head, b);
                    if h not in facts and h not in derived {
                        derived.append(h);
                    }
                }
            }
        } elif len(body) == 2 {
            for f1 in facts {
                b1 = _bind_one(body[0], f1, {});
                if b1 is None {
                    continue;
                }
                for f2 in facts {
                    b2 = _bind_one(body[1], f2, b1);
                    if b2 is not None {
                        h = _instantiate(head, b2);
                        if h not in facts and h not in derived {
                            derived.append(h);
                        }
                    }
                }
            }
        }
    }
    return sorted(derived);
}
