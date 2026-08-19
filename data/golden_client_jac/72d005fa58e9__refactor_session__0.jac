"""Guestbook get_guestbook: declarations separated from impl bodies."""

obj GuestEntry { has id: str, name: str, message: str, created_at: str; }

edge OnDay {}
edge Signed {}

node Day { has date: str = ""; }
node Visitor {
    has name: str = "", message: str = "", created_at: str = "";

    def to_view -> GuestEntry;
}

impl Visitor.to_view {
    return GuestEntry(id="", name=self.name, message=self.message, created_at=self.created_at);
}

walker get_guestbook {
    has results: list[GuestEntry] = [],
        reports: list[list[GuestEntry]] = [];

    can run with Root entry;
    can descend with Day entry;
    can gather with Visitor entry;
    can deliver with Root exit;
}

impl get_guestbook.run {
    visit [root-->[?:Day]];
}

impl get_guestbook.descend {
    visit [here-->[?:Visitor]];
}

impl get_guestbook.gather {
    self.results.append(here.to_view());
}

impl get_guestbook.deliver {
    self.results.sort(key=lambda e: GuestEntry : e.created_at, reverse=True);
    report self.results[:50];
}

with entry {
    d = (root +>: OnDay() :+> Day(date="2020-01-01"))[0];
    d +>: Signed() :+> Visitor(name="alice", message="first", created_at="2020-01-01T01:00:00Z");
    d +>: Signed() :+> Visitor(name="bob", message="second", created_at="2020-01-01T02:00:00Z");
    d +>: Signed() :+> Visitor(name="carol", message="third", created_at="2020-01-01T03:00:00Z");
    res = root spawn get_guestbook();
    entries = res.reports[0];
    print("count:", len(entries));
    print("names_by_recency:", [e.name for e in entries]);
    print("messages_by_recency:", [e.message for e in entries]);
    print("names_sorted:", sorted([e.name for e in entries]));
}
