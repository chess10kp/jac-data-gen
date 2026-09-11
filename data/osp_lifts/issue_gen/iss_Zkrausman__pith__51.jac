"""Zkrausman/pith#51 — deterministic portfolio planning scheduler."""

class CycleError(Exception) {}

node Ticket {
    has tid: str;
    has score: int = 0;
}

edge Blocks {}

obj PortfolioStore {
    has tickets: dict[str, Ticket] = {};
}

walker DownstreamReach {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Ticket entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.reached.append(here.tid);
        visit [<-:Blocks:<-][?:Ticket];
    }
}

def load_portfolio(
    ticket_ids: list[str],
    block_edges: list[tuple[str, str]],
    scores: dict[str, int],
) -> PortfolioStore {
    store = PortfolioStore();
    for tid in ticket_ids {
        nd = Ticket(tid=tid, score=scores.get(tid, 0));
        root ++> nd;
        store.tickets[tid] = nd;
    }
    for (blocker, blocked) in block_edges {
        b = store.tickets.get(blocker, None);
        d = store.tickets.get(blocked, None);
        if b is not None and d is not None { d +>:Blocks:+> b; }
    }
    return store;
}

def _topo_layers(store: PortfolioStore) -> list[list[str]] {
    indegree: dict[str, int] = {};
    rev: dict[str, list[str]] = {};
    for tid in store.tickets {
        indegree[tid] = 0;
        rev[tid] = [];
    }
    for tid in store.tickets {
        nd = store.tickets[tid];
        for blk in [nd ->:Blocks:->][?:Ticket] {
            indegree[tid] += 1;
            rev[blk.tid].append(tid);
        }
    }
    layers: list[list[str]] = [];
    visited: dict[str, bool] = {};
    ready: dict[str, bool] = {};
    for tid in store.tickets {
        if indegree[tid] == 0 { ready[tid] = True; }
    }
    while len(ready) > 0 {
        layer = sorted([tid for tid in ready.keys()]);
        layers.append(layer);
        next_ready: dict[str, bool] = {};
        for node in layer {
            visited[node] = True;
            for other in rev.get(node, []) {
                indegree[other] -= 1;
                if indegree[other] == 0 and not (other in visited) {
                    next_ready[other] = True;
                }
            }
        }
        ready = next_ready;
    }
    if len(visited) != len(store.tickets) {
        raise CycleError("hard dependency cycle");
    }
    return layers;
}

def planning_frontier(store: PortfolioStore, planned: list[str]) -> list[str] {
    done: dict[str, bool] = {};
    for p in planned { done[p] = True; }
    layers = _topo_layers(store);
    for layer in layers {
        frontier: list[str] = [];
        for t in layer {
            if not (t in done) { frontier.append(t); }
        }
        if len(frontier) > 0 { return sorted(frontier); }
    }
    return [];
}

def recommend_next(store: PortfolioStore, planned: list[str]) -> str | None {
    frontier = planning_frontier(store, planned);
    if len(frontier) == 0 { return None; }
    best = frontier[0];
    for t in frontier {
        ts = store.tickets.get(t, None);
        bs = store.tickets.get(best, None);
        if ts is not None and bs is not None {
            if ts.score > bs.score or (ts.score == bs.score and t > best) {
                best = t;
            }
        }
    }
    return best;
}

def downstream_reach(store: PortfolioStore, `root: str) -> list[str] {
    nd = store.tickets.get(`root, None);
    if nd is None { return []; }
    w = nd spawn DownstreamReach(claimed={}, reached=[]);
    out: list[str] = [];
    for tid in w.reached {
        if tid != `root { out.append(tid); }
    }
    return sorted(out);
}
