import from lighthouses { add_lamp, assign_keeper, douse, log_night, due_for_bulb, keepers_at }

test "stations are unique" {
    assert add_lamp("Fastnet", 1000.0);
    assert not add_lamp("Fastnet", 50.0);
    assert add_lamp("Hook", 800.0);
    assert log_night(10.0) == 2;
}

test "keepers belong to their station" {
    add_lamp("Hook", 800.0);
    add_lamp("Baily", 800.0);
    assert assign_keeper("Hook", "Maeve");
    assert assign_keeper("Hook", "Aidan");
    assert assign_keeper("Baily", "Ciara");
    assert not assign_keeper("Tuskar", "Nobody");
    assert keepers_at("Hook") == ["Aidan", "Maeve"];
    assert keepers_at("Baily") == ["Ciara"];
    assert len(keepers_at("Tuskar")) == 0;
}

test "dousing stops burn and bulb alerts" {
    add_lamp("A", 100.0);
    add_lamp("B", 100.0);
    add_lamp("C", 1000.0);
    assert log_night(50.0) == 3;
    assert len(due_for_bulb()) == 0;
    assert douse("B");
    assert not douse("B");
    assert not douse("Z");
    assert log_night(40.0) == 2;
    assert due_for_bulb() == ["A"];
    assert log_night(900.0) == 2;
    assert due_for_bulb() == ["A", "C"];
}

test "bulb threshold is ninety percent" {
    add_lamp("edge", 100.0);
    add_lamp("under", 100.0);
    log_night(89.5);
    douse("under");
    assert len(due_for_bulb()) == 0;
    log_night(0.5);
    assert due_for_bulb() == ["edge"];
}
