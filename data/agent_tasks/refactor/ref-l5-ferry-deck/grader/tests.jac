import from main { add_sailing, book, cancel, move, manifest, free_space, day_passengers }

def setup {
    add_sailing("AM1", 1, 3, 5);
    add_sailing("PM1", 1, 2, 2);
    add_sailing("AM2", 2, 4, 10);
}

test "sailings are unique and bookings validated" {
    assert add_sailing("AM1", 1, 3, 5);
    assert not add_sailing("AM1", 2, 9, 9);
    assert book("XX", "r1", "car", 1) == "unknown sailing";
    assert book("AM1", "r1", "boat", 1) == "bad booking";
    assert book("AM1", "r1", "foot", 0) == "bad booking";
    assert book("AM1", "r1", "car", 2) == "ok";
    assert book("AM1", "r1", "foot", 1) == "duplicate ref";
    assert free_space("AM1") == [2, 5];
    assert free_space("XX") == [0, 0];
}

test "lanes and seats are counted per vehicle" {
    setup();
    assert book("AM1", "v1", "van", 3) == "ok";
    assert book("AM1", "c1", "car", 4) == "ok";
    assert book("AM1", "c2", "car", 1) == "sold out";
    assert book("AM1", "f1", "foot", 4) == "ok";
    assert book("AM1", "f2", "foot", 2) == "sold out";
    assert book("AM1", "f3", "foot", 1) == "ok";
    assert free_space("AM1") == [0, 0];
    assert manifest("AM1") == ["c1", "f1", "f3", "v1"];
    assert len(manifest("PM1")) == 0;
}

test "cancel frees the space" {
    setup();
    book("PM1", "v1", "van", 2);
    book("PM1", "f1", "foot", 2);
    assert cancel("v1");
    assert not cancel("v1");
    assert not cancel("zz");
    assert free_space("PM1") == [2, 0];
    assert book("PM1", "c1", "car", 1) == "ok";
    assert manifest("PM1") == ["c1", "f1"];
}

test "moving a booking between sailings" {
    setup();
    book("AM1", "v1", "van", 2);
    book("AM1", "f1", "foot", 2);
    book("PM1", "c1", "car", 1);
    assert move("zz", "PM1") == "unknown ref";
    assert move("v1", "XX") == "unknown sailing";
    assert move("v1", "PM1") == "sold out";
    assert move("v1", "AM1") == "ok";
    assert move("v1", "AM2") == "ok";
    assert manifest("AM1") == ["f1"];
    assert manifest("AM2") == ["v1"];
    assert free_space("AM1") == [3, 3];
    assert free_space("AM2") == [2, 10];
    assert move("f1", "PM1") == "ok";
    assert free_space("PM1") == [1, 0];
    assert book("AM2", "v1", "car", 1) == "duplicate ref";
}

test "passengers per day" {
    setup();
    book("AM1", "v1", "van", 3);
    book("AM1", "f1", "foot", 2);
    book("PM1", "c1", "car", 4);
    book("AM2", "f2", "foot", 5);
    assert day_passengers(1) == 9;
    assert day_passengers(2) == 5;
    assert day_passengers(3) == 0;
    move("f2", "PM1");
    assert day_passengers(1) == 9;
    move("v1", "AM2");
    assert day_passengers(1) == 6;
    assert day_passengers(2) == 8;
}
