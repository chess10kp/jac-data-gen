"""kevin-earl-denny/vibe-code-boilerplate#285 — Ticket blocking chain highlight."""

node Ticket { has tid: str; }
edge Blocks {}

obj TicketBoard { has tickets: dict[str, Ticket] = {}; }

walker UpstreamWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Ticket entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.found.append(here.tid);
        for blk in [here <-:Blocks:<-][?:Ticket] {
            if not (blk.tid in self.claimed) { visit [blk]; }
        }
    }
}

walker DownstreamWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Ticket entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.found.append(here.tid);
        visit [->:Blocks:->][?:Ticket];
    }
}

def load_tickets(
    tickets: list[str],
    block_edges: list[tuple[str, str]],
) -> TicketBoard {
    board = TicketBoard();
    for tid in tickets {
        nd = Ticket(tid=tid);
        root ++> nd;
        board.tickets[tid] = nd;
    }
    for (blocker, blocked) in block_edges {
        a = board.tickets.get(blocker, None);
        b = board.tickets.get(blocked, None);
        if a is not None and b is not None { a +>:Blocks:+> b; }
    }
    return board;
}

def highlight_chain(board: TicketBoard, ticket_id: str) -> list[str] {
    nd = board.tickets.get(ticket_id, None);
    if nd is None { return []; }
    acc: dict[str, bool] = {ticket_id: True};
    up = nd spawn UpstreamWalk(claimed={}, found=[]);
    for t in up.found { acc[t] = True; }
    down = nd spawn DownstreamWalk(claimed={}, found=[]);
    for t in down.found { acc[t] = True; }
    out: list[str] = [];
    for k in acc.keys() { out.append(k); }
    return sorted(out);
}
