"""jhonDoe15/skills#48 — Carve plan ticket frontier calculation."""

node TicketNode { has tid: str; }
edge BlockedBy {}

obj PlanGraph {
    has tickets: dict[str, TicketNode] = {};
    has done: dict[str, bool] = {};
}

walker CycleProbe {
    has visited: dict[str, bool] = {};
    has stack: dict[str, bool] = {};
    has errors: list[tuple[str, str]] = [];

    can step with TicketNode entry {
        if here.tid in self.visited { skip; }
        self.visited[here.tid] = True;
        self.stack[here.tid] = True;
        for blk in [here <-:BlockedBy:<-][?:TicketNode] {
            if blk.tid in self.stack {
                self.errors.append((blk.tid, here.tid));
            } else {
                if not (blk.tid in self.visited) { visit [blk]; }
            }
        }
        self.stack[here.tid] = False;
    }
}

def load_plan_graph(
    tickets: list[str],
    deps: list[tuple[str, str]],
    done: list[str],
) -> PlanGraph {
    g = PlanGraph();
    for tid in tickets {
        nd = TicketNode(tid=tid);
        root ++> nd;
        g.tickets[tid] = nd;
    }
    for (blocker, task) in deps {
        blk = g.tickets.get(blocker, None);
        tgt = g.tickets.get(task, None);
        if blk is not None and tgt is not None { blk +>:BlockedBy:+> tgt; }
    }
    for d in done { g.done[d] = True; }
    return g;
}

def frontier(g: PlanGraph) -> list[str] {
    ready: list[str] = [];
    for (tid, nd) in g.tickets.items() {
        if g.done.get(tid, False) { continue; }
        pending = False;
        for blk in [nd <-:BlockedBy:<-][?:TicketNode] {
            if not g.done.get(blk.tid, False) { pending = True; }
        }
        if not pending { ready.append(tid); }
    }
    return sorted(ready);
}

def detect_plan_cycles(g: PlanGraph) -> list[tuple[str, str]] {
    errors: list[tuple[str, str]] = [];
    visited: dict[str, bool] = {};
    for k in sorted(g.tickets.keys()) {
        if k in visited { continue; }
        nd = g.tickets[k];
        w = nd spawn CycleProbe(visited=visited, stack={}, errors=[]);
        errors = errors + w.errors;
        visited = w.visited;
    }
    return sorted(errors);
}

def mark_done(g: PlanGraph, ticket_id: str) {
    if ticket_id in g.tickets { g.done[ticket_id] = True; }
}
