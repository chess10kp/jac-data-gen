import from course { Course }

def sample -> Course {
    c = Course(name="Birch Hill");
    c.add_control("S", 0);
    c.add_control("A", 10);
    c.add_control("B", 20);
    c.add_control("C", 30);
    c.add_control("D", 40);
    c.add_leg("S", "A", 300);
    c.add_leg("A", "B", 450);
    c.add_leg("S", "C", 800);
    c.add_leg("C", "A", 120);
    c.add_leg("D", "S", 500);
    return c;
}

test "controls are unique and legs need both ends" {
    c = Course(name="x");
    assert c.add_control("A", 5);
    assert not c.add_control("A", 7);
    assert not c.add_leg("A", "Z", 100);
    assert not c.add_leg("Q", "A", 100);
    assert c.add_control("B", 1);
    assert c.add_leg("A", "B", 100);
}

test "reachable follows one-way legs" {
    c = sample();
    assert c.reachable("S") == ["A", "B", "C"];
    assert c.reachable("C") == ["A", "B"];
    assert len(c.reachable("B")) == 0;
    assert c.reachable("D") == ["A", "B", "C", "S"];
    assert len(c.reachable("nope")) == 0;
}

test "points count each control once" {
    c = sample();
    assert c.points_from("S") == 60;
    assert c.points_from("D") == 100;
    assert c.points_from("B") == 20;
    assert c.points_from("nope") == 0;
}

test "cycles terminate" {
    c = sample();
    c.add_leg("B", "S", 600);
    assert c.reachable("A") == ["B", "C", "S"];
    assert c.points_from("A") == 60;
}

test "longest leg out of a control" {
    c = sample();
    assert c.longest_leg_from("S") == 800;
    assert c.longest_leg_from("B") == 0;
    c.add_leg("B", "C", 50);
    assert c.longest_leg_from("B") == 50;
    assert c.longest_leg_from("nope") == 0;
}

test "two courses do not share controls" {
    a = sample();
    b = Course(name="Other");
    b.add_control("S", 1);
    b.add_control("A", 2);
    assert len(b.reachable("S")) == 0;
    assert b.points_from("S") == 1;
    assert a.points_from("S") == 60;
}
