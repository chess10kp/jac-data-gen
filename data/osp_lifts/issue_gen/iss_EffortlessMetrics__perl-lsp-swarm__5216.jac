"""OSP lift for EffortlessMetrics/perl-lsp-swarm#5216 — stage invalidation cascade."""

node Stage {
    has name: str;
}

edge Invalidates {}

walker InvalidateWalker {
    has order: list[str] = [];
    has claimed: dict[str, bool] = {};
    has start: str = "";

    can begin with Root entry {
        for s in [-->][?:Stage] {
            if s.name == self.start {
                visit [s];
            }
        }
    }

    can step with Stage entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.order.append(here.name);
        visit [-->];
    }

    can finish with Root exit {
        report self.order;
    }
}

def _wire(deps: dict[str, list[str]]) -> None {
    nodes: dict[str, Stage] = {};
    for (src, tgts) in deps.items() {
        if src not in nodes {
            nodes[src] = Stage(name=src);
            root ++> nodes[src];
        }
        for t in tgts {
            if t not in nodes {
                nodes[t] = Stage(name=t);
                root ++> nodes[t];
            }
            nodes[src] +>:Invalidates:+> nodes[t];
        }
    }
}

def invalidate_stages(changed: str, deps: dict[str, list[str]]) -> list[str] {
    _wire(deps);
    w = root spawn InvalidateWalker(start=changed);
    return w.reports[0] if w.reports else [];
}

def memo_ancestors(node: str, parent: dict[str, str]) -> list[str] {
    chain: list[str] = [];
    cur = node;
    while cur in parent {
        cur = parent[cur];
        chain.append(cur);
    }
    return chain;
}

def provider_utility_hit(cache: dict, key: str) -> tuple[bool, object] {
    if key in cache {
        return (True, cache[key]);
    }
    return (False, None);
}
