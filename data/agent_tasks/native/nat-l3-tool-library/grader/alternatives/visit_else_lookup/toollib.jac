"""Neighbourhood tool library: tools and members live on root; loans are Lent edges."""

node Tool {
    has code: str;
    has name: str;
}

node Member {
    has card: str;
}

edge Lent: Member --> Tool {
    has due_day: int;
}

obj Receipt {
    has ok: bool;
    has reason: str = "";
    has due_day: int = 0;
}

"""Register a tool once; registering an existing code just renames it."""
walker RegisterTool {
    has code: str;
    has name: str;

    can register with Root entry {
        found = [root -->[?:Tool, code == self.code]];
        if found {
            found[0].name = self.name;
        } else {
            root ++> Tool(code=self.code, name=self.name);
        }
        report Receipt(ok=True);
    }
}

def find_tool(code: str) -> Tool | None {
    for t in [root -->[?:Tool]] {
        if t.code == code {
            return t;
        }
    }
    return None;
}

"""Checkout walks to the member node (creating it on first use) and lends from there."""
walker Checkout {
    has card: str;
    has code: str;
    has day: int;
    has loan_days: int = 7;
    has tool: Tool | None = None;

    can locate with Root entry {
        self.tool = find_tool(self.code);
        if self.tool is None {
            report Receipt(ok=False, reason="unknown tool");
            disengage;
        }
        if [self.tool <-:Lent:<-] {
            report Receipt(ok=False, reason="already lent");
            disengage;
        }
        visit [-->[?:Member, card == self.card]] else {
            fresh = here ++> Member(card=self.card);
            visit fresh;
        }
    }

    can lend with Member entry {
        held = len([here ->:Lent:->]);
        if held >= 2 {
            report Receipt(ok=False, reason="limit reached");
            disengage;
        }
        tool = self.tool;
        if tool is not None {
            due = self.day + self.loan_days;
            here +>:Lent(due_day=due):+> tool;
            report Receipt(ok=True, reason="", due_day=due);
        }
    }
}

walker Return {
    has code: str;
    has done: bool = False;

    can start with Root entry {
        visit [-->[?:Member]];
    }

    can check with Member entry {
        for t in [here ->:Lent:->[?:Tool, code == self.code]] {
            for doomed in [edge here ->:Lent:-> t] {
                del doomed;
            }
            self.done = True;
        }
    }

    can finish with Root exit {
        if self.done {
            report Receipt(ok=True, reason="");
        } else {
            report Receipt(ok=False, reason="not lent");
        }
    }
}

walker OverdueReport {
    has today: int;
    has rows: list[dict[str, any]] = [];

    can start with Root entry {
        visit [-->[?:Member]];
    }

    can scan with Member entry {
        for e in [edge here ->:Lent:->] {
            if e.due_day < self.today {
                for t in [here ->:Lent:due_day == e.due_day:->] {
                    row = {"due": e.due_day, "code": t.code, "card": here.card};
                    if row not in self.rows {
                        self.rows.append(row);
                    }
                }
            }
        }
    }

    can finish with Root exit {
        ordered = sorted(self.rows, key=lambda (r: dict[str, any]) { (r["due"], r["code"]); });
        report [f"{r['card']}:{r['code']}" for r in ordered];
    }
}
