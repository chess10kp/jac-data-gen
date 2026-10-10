"""IT help desk: Ticket nodes (numbered via a Counter node) with Comment nodes."""

glob PRIORITY: dict[str, int] = {"high": 0, "normal": 1, "low": 2};

node Counter {
    has last: int = 0;
}

node Ticket {
    has number: int;
    has subject: str;
    has priority: str = "normal";
    has status: str = "open";
    has agent: str = "";
}

node Comment {
    has seq: int;
    has author: str;
    has body: str;
}

def comment_seq(c: Comment) -> int {
    return c.seq;
}

def ticket_order(t: Ticket) -> tuple[int, int] {
    return (PRIORITY.get(t.priority, 9), t.number);
}

def ticket_view(t: Ticket) -> dict[str, any] {
    comments = sorted([c for c in [t -->[?:Comment]]], key=comment_seq);
    return {"number": t.number, "subject": t.subject, "priority": t.priority, "status": t.status,
            "agent": t.agent, "comments": [{"author": c.author, "body": c.body} for c in comments]};
}

def find_ticket(n: int) -> Ticket | None {
    for t in [root -->[?:Ticket]] {
        if t.number == n {
            return t;
        }
    }
    return None;
}

walker:pub open_ticket {
    has subject: str;
    has priority: str = "normal";

    can open with Root entry {
        if not self.subject.strip() {
            report {"error": "subject required"};
            return;
        }
        if self.priority not in PRIORITY {
            report {"error": f"bad priority {self.priority}"};
            return;
        }
        counters = [c for c in [here -->[?:Counter]]];
        counter = counters[0] if counters else here ++> Counter();
        counter.last += 1;
        t = here ++> Ticket(number=counter.last, subject=self.subject.strip(), priority=self.priority);
        report ticket_view(t);
    }
}

walker TicketAction {
    """Base: resolve `number` to a ticket and visit it, or report an error."""
    has number: int;

    can locate with Root entry {
        t = find_ticket(self.number);
        if t is None {
            report {"error": f"no ticket {self.number}"};
            disengage;
        }
        visit t;
    }
}

walker:pub assign_ticket(TicketAction) {
    has agent: str;

    can act with Ticket entry {
        if not self.agent.strip() {
            report {"error": "agent required"};
            return;
        }
        here.agent = self.agent.strip();
        report ticket_view(here);
    }
}

walker:pub add_comment(TicketAction) {
    has author: str;
    has body: str;

    can act with Ticket entry {
        if here.status == "closed" {
            report {"error": "ticket is closed"};
            return;
        }
        here ++> Comment(seq=len([here -->[?:Comment]]) + 1, author=self.author, body=self.body);
        report ticket_view(here);
    }
}

walker:pub close_ticket(TicketAction) {
    can act with Ticket entry {
        if here.status == "closed" {
            report {"error": "already closed"};
            return;
        }
        if not here.agent {
            report {"error": "assign before closing"};
            return;
        }
        here.status = "closed";
        report ticket_view(here);
    }
}

walker:pub list_tickets {
    has status: str = "";

    can listing with Root entry {
        ts = [t for t in [here -->[?:Ticket]] if not self.status or t.status == self.status];
        ts = sorted(ts, key=ticket_order);
        report [ticket_view(t) for t in ts];
    }
}
