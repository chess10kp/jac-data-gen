"""RL driver (pure-lib | graph): guestbook.get_guestbook.deliver (sort entries by recency and report top 50).

Origin: this_is_jac/guestbook.jac (the get_guestbook.deliver logic, isolated from any io/time/graph
machinery). Deterministic: results are pre-filled with three fixed GuestEntry literals (fixed string
ids, fixed created_at timestamps), so the in-place recency sort always yields the same order. The
marked body is the unit the policy must regenerate; the with entry block exercises it on fixed inputs
and prints a deterministic projection.
"""

obj GuestEntry { has id: str, name: str, message: str, created_at: str; }

walker get_guestbook {
    has results: list[GuestEntry] = [],
        reports: list[list[GuestEntry]] = [];

    can deliver with Root exit {
        # >>>HOLE id="gb_get_guestbook_deliver" instruction="Implement the deliver ability (walker get_guestbook, on Root exit). Sort self.results in place by each entry's created_at field in descending (reverse) order, using a lambda whose parameter is typed as GuestEntry. Then report the first 50 elements of self.results."
        self.results.sort(key=lambda e: GuestEntry : e.created_at, reverse=True);
        report self.results[:50];
        # <<<HOLE
    }
}

with entry {
    seed = [
        GuestEntry(id="g1", name="alice", message="", created_at="2026-01-01T09:00:00Z"),
        GuestEntry(id="g2", name="carol", message="", created_at="2026-01-03T09:00:00Z"),
        GuestEntry(id="g3", name="bob", message="", created_at="2026-01-02T09:00:00Z")
    ];
    w = root spawn get_guestbook(results=seed);
    print(",".join([e.name for e in w.results]));
}
