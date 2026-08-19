"""RL driver (pure-lib | numeric | graph): guestbook.guestbook_stats (tally total signatures across all days)."""

edge OnDay {}
edge Signed {}

node Hub {}

node Day {
    has date: str = "";
}

node Visitor {
    has name: str = "";
}

walker SignatureCounter {
    has total: int = 0;

    can start with Hub entry {
        visit [-->[?:Day]];
    }

    can tally with Day entry {
        self.total += len([here-->[?:Visitor]]);
    }
}

with entry {
    hub = Hub();

    d1 = hub +>: OnDay() :+> Day(date="2026-06-01");
    d1[0] +>: Signed() :+> Visitor(name="a");
    d1[0] +>: Signed() :+> Visitor(name="b");

    d2 = hub +>: OnDay() :+> Day(date="2026-06-02");
    d2[0] +>: Signed() :+> Visitor(name="c");
    d2[0] +>: Signed() :+> Visitor(name="d");
    d2[0] +>: Signed() :+> Visitor(name="e");

    d3 = hub +>: OnDay() :+> Day(date="2026-06-03");
    d3[0] +>: Signed() :+> Visitor(name="f");

    print((hub spawn SignatureCounter()).total);
}
