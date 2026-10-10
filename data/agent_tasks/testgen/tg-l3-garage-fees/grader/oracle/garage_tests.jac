import from garage { Level, Car, ParkedOn, Ticket, AddLevel, Enter, Leave, Occupancy }

test "no levels means full" {
    t = (root spawn Enter(plate="AB1", minute=0)).reports[0];
    assert t.ok == False;
    assert t.reason == "full";
}

test "fills the lowest numbered level first" {
    root spawn AddLevel(number=3, spots=5);
    root spawn AddLevel(number=1, spots=1);
    root spawn AddLevel(number=2, spots=1);
    assert (root spawn Enter(plate="A", minute=0)).reports[0].level == 1;
    assert (root spawn Enter(plate="B", minute=0)).reports[0].level == 2;
    t = (root spawn Enter(plate="C", minute=0)).reports[0];
    assert t.ok == True;
    assert t.level == 3;
}

test "full garage and duplicate plate" {
    root spawn AddLevel(number=0, spots=1);
    assert (root spawn Enter(plate="A", minute=0)).reports[0].ok;
    dup = (root spawn Enter(plate="A", minute=5)).reports[0];
    assert dup.ok == False;
    assert dup.reason == "already inside";
    full = (root spawn Enter(plate="B", minute=5)).reports[0];
    assert full.reason == "full";
}

test "fees by started hour after free half hour" {
    root spawn AddLevel(number=1, spots=10);
    for (p, m) in [("p30", 30), ("p31", 31), ("p60", 60), ("p61", 61), ("p180", 180)] {
        root spawn Enter(plate=p, minute=1000);
    }
    assert (root spawn Leave(plate="p30", minute=1030)).reports[0] == 0;
    assert (root spawn Leave(plate="p31", minute=1031)).reports[0] == 3;
    assert (root spawn Leave(plate="p60", minute=1060)).reports[0] == 3;
    assert (root spawn Leave(plate="p61", minute=1061)).reports[0] == 6;
    assert (root spawn Leave(plate="p180", minute=1180)).reports[0] == 9;
}

test "leave removes the car and frees the spot" {
    root spawn AddLevel(number=1, spots=1);
    root spawn Enter(plate="A", minute=0);
    assert (root spawn Leave(plate="A", minute=10)).reports[0] == 0;
    assert len([root -->[?:Level] ->:ParkedOn:->]) == 0;
    assert (root spawn Enter(plate="B", minute=11)).reports[0].ok;
    assert (root spawn Leave(plate="A", minute=12)).reports[0] == -1;
}

test "occupancy per level and total" {
    root spawn AddLevel(number=1, spots=2);
    root spawn AddLevel(number=2, spots=2);
    root spawn AddLevel(number=3, spots=2);
    for p in ["a", "b", "c"] {
        root spawn Enter(plate=p, minute=0);
    }
    w = root spawn Occupancy();
    assert w.reports[0] == {1: 2, 2: 1, 3: 0};
    assert w.total == 3;
}
