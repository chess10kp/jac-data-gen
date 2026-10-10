import from greenhouse { Bed, Plant, Grows, PlantIn, WaterBed, DueOn, Uproot }

test "planting creates the bed once and counts plants" {
    r1 = root spawn PlantIn(bed="B1", species="basil", interval_days=2, day=1);
    r2 = root spawn PlantIn(bed="B1", species="mint", interval_days=3, day=1);
    r3 = root spawn PlantIn(bed="B2", species="sage", interval_days=5, day=1);
    assert r1.reports[0] == 1;
    assert r2.reports[0] == 2;
    assert r3.reports[0] == 1;
    assert len([root -->[?:Bed]]) == 2;
    b1 = [root -->[?:Bed, code == "B1"]][0];
    assert len([b1 ->:Grows:->]) == 2;
}

test "due when interval reached, not before" {
    root spawn PlantIn(bed="B1", species="basil", interval_days=2, day=10);
    assert len((root spawn DueOn(day=11)).reports[0]) == 0;
    w = root spawn DueOn(day=12);
    assert len(w.reports) == 1;
    assert w.reports[0] == ["B1/basil"];
}

test "watering resets the clock for that bed only" {
    root spawn PlantIn(bed="B1", species="basil", interval_days=2, day=0);
    root spawn PlantIn(bed="B1", species="chive", interval_days=4, day=0);
    root spawn PlantIn(bed="B2", species="thyme", interval_days=2, day=0);
    w = root spawn WaterBed(bed="B1", day=3);
    assert w.reports[0] == 2;
    assert (root spawn DueOn(day=4)).reports[0] == ["B2/thyme"];
    assert (root spawn DueOn(day=7)).reports[0] == ["B1/basil", "B1/chive", "B2/thyme"];
}

test "watering an unknown bed does nothing" {
    root spawn PlantIn(bed="B1", species="basil", interval_days=2, day=0);
    w = root spawn WaterBed(bed="ZZ", day=5);
    assert w.reports[0] == 0;
    assert len([root -->[?:Bed]]) == 1;
}

test "duplicates of a species are listed twice, sorted output" {
    root spawn PlantIn(bed="C", species="lettuce", interval_days=1, day=0);
    root spawn PlantIn(bed="C", species="lettuce", interval_days=1, day=0);
    root spawn PlantIn(bed="A", species="radish", interval_days=1, day=0);
    assert (root spawn DueOn(day=1)).reports[0] == ["A/radish", "C/lettuce", "C/lettuce"];
}

test "uproot removes plant nodes of one species in one bed" {
    root spawn PlantIn(bed="B1", species="mint", interval_days=1, day=0);
    root spawn PlantIn(bed="B1", species="mint", interval_days=1, day=0);
    root spawn PlantIn(bed="B1", species="basil", interval_days=1, day=0);
    root spawn PlantIn(bed="B2", species="mint", interval_days=1, day=0);
    w = root spawn Uproot(bed="B1", species="mint");
    assert w.reports[0] == 2;
    b1 = [root -->[?:Bed, code == "B1"]][0];
    assert [p.species for p in [b1 ->:Grows:->]] == ["basil"];
    assert (root spawn DueOn(day=5)).reports[0] == ["B1/basil", "B2/mint"];
    assert (root spawn Uproot(bed="B9", species="mint")).reports[0] == 0;
}
