"""RL driver (guestbook): guestbook.get_guestbook.gather.

Origin: this_is_jac/guestbook.jac. `get_guestbook` walks root -> Day -> Visitor
in one pass; `descend` enqueues each Day's visitors and `gather` accumulates a
view per visitor. The marked body is `gather`; the entry block builds a fixed
guestbook and prints the deterministic, recency-sorted entries. (The original
walks root.shared; inlined here as root so it runs under plain `jac run`.)
"""

obj GuestEntry { has id: str, name: str, message: str, created_at: str; }

edge OnDay {}
edge Signed {}

node Day { has date: str = ""; }
node Visitor {
    has name: str = "", message: str = "", created_at: str = "";

    def to_view -> GuestEntry {
        return GuestEntry(id="", name=self.name, message=self.message, created_at=self.created_at);
    }
}

walker get_guestbook {
    has results: list[GuestEntry] = [],
        reports: list[list[GuestEntry]] = [];

    can run with Root entry {
        visit [root-->[?:Day]];
    }

    can descend with Day entry {
        visit [here-->[?:Visitor]];
    }

    can gather with Visitor entry {
        # >>>HOLE id="gb_get_guestbook_gather" instruction="Implement the gather ability (walker get_guestbook, on Visitor entry). Append the current visitor's view, here.to_view(), to self.results."
        self.results.append(here.to_view());
        # <<<HOLE
    }

    can deliver with Root exit {
        self.results.sort(key=lambda e: GuestEntry : e.created_at, reverse=True);
        report self.results[:50];
    }
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
