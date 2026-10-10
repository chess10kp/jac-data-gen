import from rounds { add_bed, plant, promote, water_bed, due_on, uproot, age }

def seed -> None {
    add_bed("east");
    add_bed("west");
    plant("east", "t1", "tomato", 2, 0);
    plant("east", "b1", "basil", 1, 0);
    plant("west", "c1", "cactus", 10, 0);
    promote("t1");
    promote("c1");
}

test "beds and plants are unique" {
    assert add_bed("east");
    assert not add_bed("east");
    assert plant("east", "t1", "tomato", 3, 0);
    assert not plant("east", "t1", "tomato", 3, 0);
    assert not plant("north", "x1", "leek", 3, 0);
    add_bed("west");
    assert not plant("west", "t1", "tomato", 3, 0);
    assert plant("west", "t2", "tomato", 3, 0);
}

test "growth stages advance and stop at mature" {
    seed();
    assert promote("b1") == "growing";
    assert promote("b1") == "mature";
    assert promote("b1") == "mature";
    assert promote("t1") == "mature";
    assert promote("nope") == "";
}

test "seedlings need water daily, others by interval" {
    seed();
    plant("west", "s1", "sage", 5, 0);
    assert len(due_on(0)) == 0;
    assert due_on(1) == ["east/b1", "west/s1"];
    assert due_on(2) == ["east/b1", "east/t1", "west/s1"];
    assert due_on(10) == ["east/b1", "east/t1", "west/c1", "west/s1"];
}

test "watering a bed resets only that bed" {
    seed();
    assert water_bed("east", 5) == 2;
    assert water_bed("north", 5) == 0;
    assert due_on(6) == ["east/b1"];
    assert due_on(7) == ["east/b1", "east/t1"];
    assert water_bed("west", 7) == 1;
    assert due_on(16) == ["east/b1", "east/t1"];
    assert due_on(17) == ["east/b1", "east/t1", "west/c1"];
}

test "uprooting and age" {
    seed();
    plant("west", "s1", "sage", 5, 4);
    assert age("t1", 9) == 9;
    assert age("s1", 9) == 5;
    water_bed("west", 8);
    assert age("s1", 9) == 5;
    assert age("nope", 9) == -1;
    assert uproot("t1");
    assert not uproot("t1");
    assert age("t1", 9) == -1;
    assert water_bed("east", 9) == 1;
    assert promote("t1") == "";
}
