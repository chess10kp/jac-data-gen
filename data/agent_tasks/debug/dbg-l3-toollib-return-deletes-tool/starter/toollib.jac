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

walker Checkout {
    has card: str;
    has code: str;
    has day: int;
    has loan_days: int = 7;

    can lend with Root entry {
        tools = [root -->[?:Tool, code == self.code]];
        if not tools {
            report Receipt(ok=False, reason="unknown tool");
            return;
        }
        tool = tools[0];
        if len([tool <-:Lent:<-]) > 0 {
            report Receipt(ok=False, reason="already lent");
            return;
        }
        members = [root -->[?:Member, card == self.card]];
        if members {
            member = members[0];
        } else {
            member = root ++> Member(card=self.card);
        }
        if len([member ->:Lent:->]) >= 2 {
            report Receipt(ok=False, reason="limit reached");
            return;
        }
        due = self.day + self.loan_days;
        member +>:Lent(due_day=due):+> tool;
        report Receipt(ok=True, reason="", due_day=due);
    }
}

walker Return {
    has code: str;

    can give_back with Root entry {
        tools = [root -->[?:Tool, code == self.code]];
        if tools {
            tool = tools[0];
            holders = [tool <-:Lent:<-];
            if holders {
                del tool;
                report Receipt(ok=True, reason="");
                return;
            }
        }
        report Receipt(ok=False, reason="not lent");
    }
}

walker OverdueReport {
    has today: int;
    has late: list[tuple[int, str, str]] = [];

    can start with Root entry {
        visit [-->[?:Member]];
    }

    can scan with Member entry {
        for tool in [here ->:Lent:->] {
            loan = [edge here ->:Lent:-> tool][0];
            if loan.due_day < self.today {
                self.late.append((loan.due_day, tool.code, here.card));
            }
        }
    }

    can finish with Root exit {
        report [f"{card}:{code}" for (due, code, card) in sorted(self.late)];
    }
}
