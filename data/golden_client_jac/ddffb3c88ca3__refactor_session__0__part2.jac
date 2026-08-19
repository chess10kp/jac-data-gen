"""Guestbook get_guestbook walker: abilities separated into impl blocks."""

node Day { has date: str = ""; }
node Visitor { has name: str = ""; }
edge OnDay {}
edge Signed {}

walker get_guestbook {
    has names: list[str] = [];

    can run with Root entry;
    can descend with Day entry;
    can gather with Visitor entry;
    can done with Root exit;
}

impl get_guestbook.run {
    visit [-->[?:Day]];
}

impl get_guestbook.descend {
    visit [here-->[?:Visitor]];
}

impl get_guestbook.gather {
    self.names.append(here.name);
}

impl get_guestbook.done {
    self.names.sort();
}

with entry {
    if not [root-->[?:Day]] {
        d = root +>: OnDay() :+> Day(date="2026-01-01");
        d[0] +>: Signed() :+> Visitor(name="bob");
        d[0] +>: Signed() :+> Visitor(name="alice");
    }
    w = root spawn get_guestbook();
    print(",".join(w.names));
}
