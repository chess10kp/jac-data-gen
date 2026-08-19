"""RL driver (pure-lib | numeric | graph): guestbook.guestbook_stats (tally total signatures across all days).

Origin: this_is_jac/guestbook.jac (the guestbook_stats counting logic, isolated from io/time/graph/render
machinery). Deterministic: a fixed graph is built off a fresh, unpersisted hub node each run (3 Day nodes with
2/3/1 Visitors) so nothing accumulates on the persistent root; the body is a pure sum over edge counts that is
independent of traversal/iteration order. The marked body is the unit the policy must regenerate; the with entry
block exercises it on fixed inputs and prints a deterministic projection.
"""

edge OnDay {}
edge Signed {}

node Hub {}

node Day {
    has date: str = "";
}

node Visitor {
    has name: str = "";
}

def count_signatures(hub: Hub) -> int {
    # >>>HOLE id="gb_count_signatures" instruction="Initialize a counter to zero. Iterate over every Day node reachable one hop from the hub node via outgoing edges, and for each Day add to the counter the number of Visitor nodes reachable one hop from that Day via its outgoing edges. The counter ends up holding the total signature count across all days; return it."
    signatures = 0;
    for day in [hub-->[?:Day]] {
        signatures += len([day-->[?:Visitor]]);
    }
    return signatures;
    # <<<HOLE
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

    print(count_signatures(hub));
}
