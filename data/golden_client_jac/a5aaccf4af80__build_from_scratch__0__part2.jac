obj GuestEntry { has id: str, name: str, message: str, created_at: str; }

walker get_guestbook {
    has results: list[GuestEntry] = [],
        reports: list[list[GuestEntry]] = [];

    can deliver with Root exit {
        self.results.sort(key=lambda e: GuestEntry : e.created_at, reverse=True);
        report self.results[:50];
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
