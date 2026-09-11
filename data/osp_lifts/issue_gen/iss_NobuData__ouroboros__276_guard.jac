"""Guard: NobuData/ouroboros#276."""

node Ticket { has tid: str; }
edge Blocks {}

obj TicketBoard {
    has tickets: dict[str, Ticket] = {};
}

walker CycleProbe {
    has visited: dict[str, bool] = {};
    has stack: dict[str, bool] = {};
    has found: bool = False;

    can step with Ticket entry {
        if here.tid in self.visited { skip; }
        self.visited[here.tid] = True;
        self.stack[here.tid] = True;
        for prereq in [here <-:Blocks:<-][?:Ticket] {
            if prereq.tid in self.stack {
                self.found = True;
            } else {
                if not (prereq.tid in self.visited) { visit [prereq]; }
            }
        }
        self.stack[here.tid] = False;
    }
}

def load_ticket_board(tickets: list[str], blocks: list[tuple[str, str]]) -> TicketBoard {
    b = TicketBoard();
    for tid in tickets {
        nd = Ticket(tid=tid);
        root ++> nd;
        b.tickets[tid] = nd;
    }
    for (blocker, blocked) in blocks {
        blk = b.tickets.get(blocker, None);
        tgt = b.tickets.get(blocked, None);
        if blk is not None and tgt is not None { blk +>:Blocks:+> tgt; }
    }
    return b;
}

def has_dependency_cycle(board: TicketBoard) -> bool {
    visited: dict[str, bool] = {};
    for k in sorted(board.tickets.keys()) {
        if k in visited { continue; }
        w = board.tickets[k] spawn CycleProbe(visited=visited, stack={}, found=False);
        if w.found { return True; }
        visited = w.visited;
    }
    return False;
}

def push_order(board: TicketBoard) -> list[str] {
    indeg: dict[str, int] = {};
    rev: dict[str, list[str]] = {};
    for tid in board.tickets.keys() {
        indeg[tid] = 0;
        rev[tid] = [];
    }
    for (tid, nd) in board.tickets.items() {
        for prereq in [nd <-:Blocks:<-][?:Ticket] {
            indeg[tid] += 1;
            rev[prereq.tid].append(tid);
        }
    }
    frontier: list[str] = [];
    for tid in sorted(board.tickets.keys()) {
        if indeg[tid] == 0 { frontier.append(tid); }
    }
    order: list[str] = [];
    while len(frontier) > 0 {
        cur = frontier.pop(0);
        order.append(cur);
        for nxt in sorted(rev.get(cur, [])) {
            indeg[nxt] -= 1;
            if indeg[nxt] == 0 { frontier.append(nxt); }
        }
        frontier = sorted(frontier);
    }
    return order if len(order) == len(board.tickets) else [];
}

test "acyclic push order" {
    b = load_ticket_board(
        ["OTA-1", "OTA-2", "OTA-3"],
        [("OTA-1", "OTA-2"), ("OTA-2", "OTA-3")],
    );
    assert not has_dependency_cycle(b);
    assert push_order(b) == ["OTA-1", "OTA-2", "OTA-3"];
}

test "cycle blocks push order" {
    c = load_ticket_board(["A", "B"], [("A", "B"), ("B", "A")]);
    assert has_dependency_cycle(c);
    assert push_order(c) == [];
}

test "diamond acyclic order" {
    b = load_ticket_board(
        ["hub", "left", "right", "leaf"],
        [
            ("hub", "left"),
            ("hub", "right"),
            ("left", "leaf"),
            ("right", "leaf"),
        ],
    );
    assert not has_dependency_cycle(b);
    assert push_order(b) == ["hub", "left", "right", "leaf"];
}
