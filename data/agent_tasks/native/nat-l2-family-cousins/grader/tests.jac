import from family { Person, ParentOf, child_of, Cousins }

test "no grandparents means no cousins" {
    a = child_of("ann", []);
    w = a spawn Cousins();
    assert len(w.reports) == 1;
    assert len(w.reports[0]) == 0;
}

test "classic first cousins on one side" {
    gp = child_of("granny", []);
    mum = child_of("mum", [gp]);
    aunt = child_of("aunt", [gp]);
    me = child_of("me", [mum]);
    sis = child_of("sis", [mum]);
    c1 = child_of("zoe", [aunt]);
    c2 = child_of("abe", [aunt]);
    w = me spawn Cousins();
    assert w.reports[0] == ["abe", "zoe"];
}

test "half siblings are not cousins" {
    gp = child_of("gp", []);
    dad = child_of("dad", [gp]);
    other = child_of("stepmum", []);
    mum = child_of("mum", []);
    me = child_of("me", [dad, mum]);
    half = child_of("half", [dad, other]);
    w = me spawn Cousins();
    assert len(w.reports[0]) == 0;
}

test "both sides of the family, double cousin listed once" {
    g1 = child_of("g1", []);
    g2 = child_of("g2", []);
    mum = child_of("mum", [g1]);
    dad = child_of("dad", [g2]);
    aunt = child_of("aunt", [g1]);
    uncle = child_of("uncle", [g2]);
    me = child_of("me", [mum, dad]);
    dbl = child_of("dbl", [aunt, uncle]);
    one = child_of("one", [aunt]);
    w = me spawn Cousins();
    assert w.reports[0] == ["dbl", "one"];
}

test "aunts uncles and grandchildren of other lines excluded" {
    gp = child_of("gp", []);
    other_gp = child_of("other_gp", []);
    mum = child_of("mum", [gp]);
    aunt = child_of("aunt", [gp]);
    me = child_of("me", [mum]);
    stranger_parent = child_of("sp", [other_gp]);
    stranger = child_of("stranger", [stranger_parent]);
    cuz = child_of("cuz", [aunt]);
    w = me spawn Cousins();
    assert w.reports[0] == ["cuz"];
}

test "walker leaves the tree unchanged" {
    gp = child_of("gp", []);
    mum = child_of("mum", [gp]);
    aunt = child_of("aunt", [gp]);
    me = child_of("me", [mum]);
    child_of("cuz", [aunt]);
    me spawn Cousins();
    assert len([gp ->:ParentOf:->]) == 2;
    assert len([me <-:ParentOf:<-]) == 1;
    assert len([root -->[?:Person]]) == 1;
}
