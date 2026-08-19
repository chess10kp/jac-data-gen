"""RL driver (pure-lib | graph): guestbook.get_guestbook.descend (enqueue a Day's visitors).

Origin: this_is_jac/guestbook.jac (the get_guestbook.descend logic, isolated from any io/time/graph
machinery). Deterministic: the with entry block builds a fixed local graph (one Day with two
Visitors, fixed names), and the gathered names are sorted before printing, so the output is order-
independent and stable. The marked body is the unit the policy must regenerate; the surrounding
scaffold abilities (run/gather/done) stay outside the hole.
"""

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
        # >>>HOLE id="gb_get_guestbook_descend" instruction="Implement the descend ability (walker get_guestbook, on Day entry). Visit every Visitor node reachable one step out from the current node (here)."
        visit [here-->[?:Visitor]];
        # <<<HOLE
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
