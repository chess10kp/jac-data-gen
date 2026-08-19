node Day { has date: str = ""; }
node Visitor { has name: str = ""; }
edge OnDay {}
edge Signed {}

walker get_guestbook {
    has names: list[str] = [];

    can run with Root entry {
        visit [-->[?:Day]];
    }

    can descend with Day entry {
        visit [here-->[?:Visitor]];
    }

    can gather with Visitor entry {
        self.names.append(here.name);
    }

    can done with Root exit {
        self.names.sort();
    }
}

with entry {
    # Idempotent build: only attach the fixed graph if the shared root has no
    # Day yet, so re-running on the persisted root never accumulates duplicates.
    if not [root-->[?:Day]] {
        d = root +>: OnDay() :+> Day(date="2026-01-01");
        d[0] +>: Signed() :+> Visitor(name="bob");
        d[0] +>: Signed() :+> Visitor(name="alice");
    }
    w = root spawn get_guestbook();
    print(",".join(w.names));
}
