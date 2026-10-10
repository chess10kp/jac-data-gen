import from family { child_of, Cousins }

test "half sibling is not a cousin" {
    gp = child_of("gp", []);
    dad = child_of("dad", [gp]);
    aunt = child_of("aunt", [gp]);
    mum = child_of("mum", []);
    step = child_of("step", []);
    me = child_of("me", [dad, mum]);
    half = child_of("half", [dad, step]);
    cuz = child_of("cuz", [aunt]);
    w = me spawn Cousins();
    assert w.reports[0] == ["cuz"];
}
