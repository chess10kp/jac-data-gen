import from collection { Museum, acquire, lend, OnDisplay }

test "borrower shows the work in the last loan year" {
    a = root ++> Museum(name="a");
    b = root ++> Museum(name="b");
    lend(acquire(a, "Orchard"), b, 2025, 2027);
    assert (b spawn OnDisplay(year=2027)).reports[0] == ["Orchard"];
}
