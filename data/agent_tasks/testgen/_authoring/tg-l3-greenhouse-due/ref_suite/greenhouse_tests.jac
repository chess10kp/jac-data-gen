import from greenhouse { Bed, Plant, Grows, PlantIn, WaterBed, DueOn }

def plant(bed: str, sp: str, every: int, day: int) -> int {
    return (root spawn PlantIn(bed=bed, species=sp, interval_days=every, day=day)).reports[0];
}

test "nothing planted means nothing due" {
    w = root spawn DueOn(day=100);
    assert len(w.reports) == 1;
    assert len(w.reports[0]) == 0;
}

test "plant is due exactly when its interval has passed" {
    plant("B", "dill", 3, 10);
    assert len((root spawn DueOn(day=12)).reports[0]) == 0;
    assert (root spawn DueOn(day=13)).reports[0] == ["B/dill"];
    assert (root spawn DueOn(day=20)).reports[0] == ["B/dill"];
}

test "a plant watered today with interval zero is due" {
    plant("B", "cress", 0, 5);
    assert (root spawn DueOn(day=5)).reports[0] == ["B/cress"];
}

test "due list is sorted bed then species" {
    plant("Z", "aloe", 1, 0);
    plant("A", "sage", 1, 0);
    plant("A", "basil", 1, 0);
    plant("M", "kale", 9, 0);
    w = root spawn DueOn(day=1);
    assert w.reports[0] == ["A/basil", "A/sage", "Z/aloe"];
    assert len(w.reports) == 1;
}

test "watering reports how many plants it watered" {
    plant("B", "a", 1, 0);
    plant("B", "b", 1, 0);
    plant("B", "c", 1, 0);
    plant("C", "d", 1, 0);
    w = root spawn WaterBed(bed="B", day=2);
    assert len(w.reports) == 1;
    assert w.reports[0] == 3;
    assert w.watered == 3;
}

test "watering sets last_watered to the day" {
    plant("B", "mint", 2, 0);
    root spawn WaterBed(bed="B", day=7);
    b = [root -->[?:Bed, code == "B"]][0];
    assert [p.last_watered for p in [b ->:Grows:->]] == [7];
}

test "watering only resets the named bed" {
    plant("B1", "mint", 2, 0);
    plant("B2", "sage", 2, 0);
    root spawn WaterBed(bed="B1", day=3);
    assert (root spawn DueOn(day=4)).reports[0] == ["B2/sage"];
    assert (root spawn DueOn(day=5)).reports[0] == ["B1/mint", "B2/sage"];
}

test "unknown bed waters nothing and creates nothing" {
    plant("B1", "mint", 2, 0);
    w = root spawn WaterBed(bed="nope", day=3);
    assert w.reports[0] == 0;
    assert len([root -->[?:Bed]]) == 1;
    assert (root spawn DueOn(day=3)).reports[0] == ["B1/mint"];
}

test "duplicate species in a bed appear twice" {
    plant("B", "pea", 1, 0);
    plant("B", "pea", 1, 0);
    assert (root spawn DueOn(day=1)).reports[0] == ["B/pea", "B/pea"];
}

test "planting into an existing bed reuses it" {
    assert plant("B", "x", 1, 0) == 1;
    assert plant("B", "y", 1, 0) == 2;
    assert len([root -->[?:Bed]]) == 1;
}
