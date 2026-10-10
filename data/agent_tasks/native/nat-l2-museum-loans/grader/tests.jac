import from collection { Museum, Artwork, Owns, LoanedTo, acquire, lend, OnDisplay }

def museum(name: str) -> Museum {
    return root ++> Museum(name=name);
}

test "owned works are on display" {
    m = museum("north");
    acquire(m, "Harbour at Dusk");
    acquire(m, "Blue Kiln");
    w = m spawn OnDisplay(year=2026);
    assert len(w.reports) == 1;
    assert w.reports[0] == ["Blue Kiln", "Harbour at Dusk"];
    assert w.shown == 2;
}

test "work on active loan elsewhere is not shown at owner" {
    a = museum("a");
    b = museum("b");
    art = acquire(a, "Salt Flats");
    acquire(a, "Ferry");
    lend(art, b, 2025, 2027);
    assert (a spawn OnDisplay(year=2026)).reports[0] == ["Ferry"];
    assert (b spawn OnDisplay(year=2026)).reports[0] == ["Salt Flats"];
}

test "loan years are inclusive on both ends" {
    a = museum("a");
    b = museum("b");
    art = acquire(a, "Orchard");
    lend(art, b, 2025, 2027);
    assert len((a spawn OnDisplay(year=2025)).reports[0]) == 0;
    assert len((a spawn OnDisplay(year=2027)).reports[0]) == 0;
    assert (b spawn OnDisplay(year=2027)).reports[0] == ["Orchard"];
}

test "past and future loans do not matter" {
    a = museum("a");
    b = museum("b");
    art = acquire(a, "Lantern");
    lend(art, b, 2020, 2021);
    lend(art, b, 2030, 2031);
    assert (a spawn OnDisplay(year=2026)).reports[0] == ["Lantern"];
    w = b spawn OnDisplay(year=2026);
    assert len(w.reports[0]) == 0;
    assert w.shown == 0;
}

test "conservation hides owned and borrowed works" {
    a = museum("a");
    b = museum("b");
    x = acquire(a, "Cracked Vase");
    x.in_conservation = True;
    y = acquire(b, "Torn Map");
    lend(y, a, 2026, 2026);
    y.in_conservation = True;
    acquire(a, "Fine Plate");
    w = a spawn OnDisplay(year=2026);
    assert w.reports[0] == ["Fine Plate"];
    assert w.shown == 1;
}

test "borrowed and owned mixed, sorted, counted" {
    a = museum("a");
    b = museum("b");
    c = museum("c");
    acquire(a, "Zinnias");
    lend(acquire(b, "Acrobats"), a, 2026, 2028);
    lend(acquire(c, "Moth"), a, 2024, 2026);
    lend(acquire(c, "Kite"), b, 2026, 2026);
    w = a spawn OnDisplay(year=2026);
    assert w.reports[0] == ["Acrobats", "Moth", "Zinnias"];
    assert w.shown == 3;
}
