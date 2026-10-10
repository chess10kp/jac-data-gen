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
    # TODO
}

walker Return {
    has code: str;
    # TODO
}

walker OverdueReport {
    has today: int;
    # TODO
}
