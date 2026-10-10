import from collection { Museum, Artwork, Owns, LoanedTo, acquire, lend, OnDisplay }

def new_museum(name: str) -> Museum {
    return root ++> Museum(name=name);
}

test "museum with nothing shows nothing" {
    m = new_museum("empty");
    w = m spawn OnDisplay(year=2026);
    assert len(w.reports) == 1;
    assert len(w.reports[0]) == 0;
    assert w.shown == 0;
}

test "acquire links the work to its owner" {
    m = new_museum("m");
    art = acquire(m, "Gull");
    owned = [m ->:Owns:->];
    assert len(owned) == 1;
    assert owned[0].title == "Gull";
    assert art.in_conservation == False;
}

test "lend creates a dated loan edge to the borrower" {
    a = new_museum("a");
    b = new_museum("b");
    art = acquire(a, "Dune");
    lend(art, b, 2024, 2025);
    assert [x.name for x in [art ->:LoanedTo:->]] == ["b"];
    e = [edge art ->:LoanedTo:->][0];
    assert e.start_year == 2024;
    assert e.end_year == 2025;
}

test "owned works listed sorted with count" {
    m = new_museum("m");
    acquire(m, "Wren");
    acquire(m, "Arches");
    acquire(m, "Mill");
    w = m spawn OnDisplay(year=2000);
    assert w.reports[0] == ["Arches", "Mill", "Wren"];
    assert w.shown == 3;
}

test "active loan moves the work to the borrower" {
    a = new_museum("a");
    b = new_museum("b");
    art = acquire(a, "Tide");
    lend(art, b, 2026, 2026);
    assert len((a spawn OnDisplay(year=2026)).reports[0]) == 0;
    wb = b spawn OnDisplay(year=2026);
    assert wb.reports[0] == ["Tide"];
    assert wb.shown == 1;
}

test "loan window is inclusive and closed outside" {
    a = new_museum("a");
    b = new_museum("b");
    art = acquire(a, "Fern");
    lend(art, b, 2030, 2032);
    assert (a spawn OnDisplay(year=2029)).reports[0] == ["Fern"];
    assert len((a spawn OnDisplay(year=2030)).reports[0]) == 0;
    assert len((a spawn OnDisplay(year=2032)).reports[0]) == 0;
    assert (a spawn OnDisplay(year=2033)).reports[0] == ["Fern"];
    assert len((b spawn OnDisplay(year=2029)).reports[0]) == 0;
    assert (b spawn OnDisplay(year=2030)).reports[0] == ["Fern"];
    assert (b spawn OnDisplay(year=2032)).reports[0] == ["Fern"];
    assert len((b spawn OnDisplay(year=2033)).reports[0]) == 0;
}

test "works in conservation are hidden everywhere" {
    a = new_museum("a");
    b = new_museum("b");
    mine = acquire(a, "Crack");
    mine.in_conservation = True;
    lent = acquire(b, "Patch");
    lend(lent, a, 2026, 2027);
    lent.in_conservation = True;
    w = a spawn OnDisplay(year=2026);
    assert len(w.reports[0]) == 0;
    assert w.shown == 0;
}

test "owned and borrowed are merged sorted and deduplicated" {
    a = new_museum("a");
    b = new_museum("b");
    acquire(a, "Same");
    acquire(a, "Kestrel");
    other = acquire(b, "Same");
    lend(other, a, 2026, 2026);
    lend(acquire(b, "Birch"), a, 2025, 2026);
    w = a spawn OnDisplay(year=2026);
    assert w.reports[0] == ["Birch", "Kestrel", "Same"];
    assert w.shown == 3;
}

test "a loan to a third museum does not show at an unrelated one" {
    a = new_museum("a");
    b = new_museum("b");
    c = new_museum("c");
    lend(acquire(a, "Opal"), b, 2026, 2026);
    assert len((c spawn OnDisplay(year=2026)).reports[0]) == 0;
}
