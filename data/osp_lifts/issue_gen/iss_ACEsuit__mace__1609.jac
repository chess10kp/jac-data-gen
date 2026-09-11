"""ACEsuit/mace#1609 — Governance ticket dependency graph for release policy."""

node GovTicket {
    has tid: str;
}

edge DependsOn {}

edge Blocks {}

obj GovStore {
    has tickets: dict[str, GovTicket] = {};
}

walker BlockerWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has anchor: str = "";

    can step with GovTicket entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        if here.tid != self.anchor { self.found.append(here.tid); }
        visit [->:DependsOn:->][?:GovTicket];
    }
}

def load_governance(
    ticket_ids: list[str],
    depends_edges: list[tuple[str, str]],
) -> GovStore {
    store = GovStore();
    for tid in ticket_ids {
        nd = GovTicket(tid=tid);
        root ++> nd;
        store.tickets[tid] = nd;
    }
    for (upstream, downstream) in depends_edges {
        u = store.tickets.get(upstream, None);
        d = store.tickets.get(downstream, None);
        if u is not None and d is not None {
            d +>:DependsOn:+> u;
            u +>:Blocks:+> d;
        }
    }
    return store;
}

def unblock_order(store: GovStore) -> list[str] {
    indegree: dict[str, int] = {};
    rev: dict[str, list[str]] = {};
    for tid in store.tickets {
        indegree[tid] = 0;
        rev[tid] = [];
    }
    for tid in store.tickets {
        nd = store.tickets[tid];
        for up in [nd ->:DependsOn:->][?:GovTicket] {
            indegree[tid] += 1;
            rev[up.tid].append(tid);
        }
    }
    order: list[str] = [];
    ready: list[str] = [];
    for tid in store.tickets {
        if indegree[tid] == 0 { ready.append(tid); }
    }
    pending = len(store.tickets);
    while pending > 0 {
        if len(ready) == 0 { return []; }
        ready.sort();
        nxt = ready[0];
        ready = ready[1:];
        order.append(nxt);
        pending -= 1;
        for other in rev.get(nxt, []) {
            indegree[other] -= 1;
            if indegree[other] == 0 { ready.append(other); }
        }
    }
    return order;
}

def transitive_blockers(store: GovStore, ticket: str) -> list[str] {
    nd = store.tickets.get(ticket, None);
    if nd is None { return []; }
    w = nd spawn BlockerWalk(claimed={}, anchor=ticket);
    return sorted(w.found);
}

def has_cycle(store: GovStore) -> bool {
    ord = unblock_order(store);
    return len(ord) != len(store.tickets);
}
