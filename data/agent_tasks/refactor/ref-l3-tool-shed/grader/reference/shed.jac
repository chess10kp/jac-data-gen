"""Community tool shed: members borrow tools for a number of days; damaged tools go to repair."""

enum Condition {
    OK = "ok",
    REPAIR = "repair",
    RETIRED = "retired"
}

node Tool {
    has code: str;
    has label: str;
    has condition: Condition = Condition.OK;
}

node Member {
    has card: str;
}

edge Lent: Member --> Tool {
    has due_day: int;
}

"""Visit every tool of a shed and collect loans that are past due."""
walker OverdueScan {
    has today: int;
    has late: list[tuple[int, str, str]] = [];

    can start with ToolShed entry {
        visit [-->[?:Tool]];
    }

    can check with Tool entry {
        loans = [edge here <-:Lent:<-];
        if loans and loans[0].due_day < self.today {
            who = [here <-:Lent:<-][0];
            self.late.append((loans[0].due_day, here.code, who.card));
        }
    }
}

node ToolShed {
    has name: str;
    has limit: int = 2;

    def tool(code: str) -> Tool | None {
        wanted = code;
        found = [self -->[?:Tool, code == wanted]];
        return found[0] if found else None;
    }

    def member(card: str) -> Member | None {
        wanted = card;
        found = [self -->[?:Member, card == wanted]];
        return found[0] if found else None;
    }

    def holder(t: Tool) -> Member | None {
        found = [t <-:Lent:<-];
        return found[0] if found else None;
    }

    def register(code: str, name: str) -> bool {
        if self.tool(code) is not None {
            return False;
        }
        self ++> Tool(code=code, label=name);
        return True;
    }

    def checkout(card: str, code: str, day: int, days: int) -> str {
        t = self.tool(code);
        if t is None {
            return "unknown tool";
        }
        if t.condition != Condition.OK {
            return "unavailable";
        }
        if self.holder(t) is not None {
            return "already lent";
        }
        m = self.member(card);
        if m is None {
            m = self ++> Member(card=card);
        }
        if len([m ->:Lent:->]) >= self.limit {
            return "limit reached";
        }
        m +>:Lent(due_day=day + days):+> t;
        return "ok";
    }

    def give_back(code: str, damaged: bool) -> bool {
        t = self.tool(code);
        if t is None {
            return False;
        }
        m = self.holder(t);
        if m is None {
            return False;
        }
        m del --> t;
        if damaged {
            t.condition = Condition.REPAIR;
        }
        return True;
    }

    def repair(code: str) -> bool {
        t = self.tool(code);
        if t is None or t.condition != Condition.REPAIR {
            return False;
        }
        t.condition = Condition.OK;
        return True;
    }

    def retire(code: str) -> bool {
        t = self.tool(code);
        if t is None or self.holder(t) is not None or t.condition == Condition.RETIRED {
            return False;
        }
        t.condition = Condition.RETIRED;
        return True;
    }

    def status(code: str) -> str {
        t = self.tool(code);
        if t is None {
            return "unknown";
        }
        if t.condition != Condition.OK {
            return t.condition.value;
        }
        return "lent" if self.holder(t) is not None else "available";
    }

    def on_loan(card: str) -> list[str] {
        m = self.member(card);
        if m is None {
            return [];
        }
        return sorted([t.code for t in [m ->:Lent:->]]);
    }

    def overdue(today: int) -> list[str] {
        w = self spawn OverdueScan(today=today);
        return [f"{card}:{code}" for (due, code, card) in sorted(w.late)];
    }
}
