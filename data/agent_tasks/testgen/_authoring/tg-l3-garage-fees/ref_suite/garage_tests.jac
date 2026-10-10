import from garage { Level, Car, ParkedOn, Ticket, AddLevel, Enter, Leave, Occupancy }

def enter(plate: str, minute: int) -> Ticket {
    return (root spawn Enter(plate=plate, minute=minute)).reports[0];
}

def leave(plate: str, minute: int) -> int {
    return (root spawn Leave(plate=plate, minute=minute)).reports[0];
}

test "add level reports its number" {
    w = root spawn AddLevel(number=4, spots=10);
    assert w.reports[0] == 4;
    lv = [root -->[?:Level]];
    assert len(lv) == 1;
    assert lv[0].spots == 10;
}

test "empty garage is full" {
    t = enter("X1", 0);
    assert t.ok == False;
    assert t.reason == "full";
    assert t.level == -1;
}

test "cars fill levels lowest number first" {
    root spawn AddLevel(number=5, spots=1);
    root spawn AddLevel(number=2, spots=2);
    assert enter("a", 0).level == 2;
    assert enter("b", 0).level == 2;
    t = enter("c", 0);
    assert t.ok == True;
    assert t.level == 5;
    assert t.reason == "";
    assert enter("d", 0).reason == "full";
}

test "a plate already inside is refused" {
    root spawn AddLevel(number=1, spots=5);
    enter("dup", 0);
    t = enter("dup", 3);
    assert t.ok == False;
    assert t.reason == "already inside";
    assert len([root -->[?:Level] ->:ParkedOn:->]) == 1;
}

test "first half hour is free" {
    root spawn AddLevel(number=1, spots=5);
    enter("a", 100);
    enter("b", 100);
    assert leave("a", 100) == 0;
    assert leave("b", 130) == 0;
}

test "fee is three per started hour after thirty minutes" {
    root spawn AddLevel(number=1, spots=9);
    for p in ["m31", "m59", "m60", "m61", "m120", "m121"] {
        enter(p, 0);
    }
    assert leave("m31", 31) == 3;
    assert leave("m59", 59) == 3;
    assert leave("m60", 60) == 3;
    assert leave("m61", 61) == 6;
    assert leave("m120", 120) == 6;
    assert leave("m121", 121) == 9;
}

test "leaving frees the spot and removes the car" {
    root spawn AddLevel(number=1, spots=1);
    enter("a", 0);
    assert enter("b", 0).ok == False;
    leave("a", 5);
    assert len([root -->[?:Level] ->:ParkedOn:->]) == 0;
    assert enter("b", 6).ok == True;
}

test "unknown plate cannot leave" {
    root spawn AddLevel(number=1, spots=1);
    assert leave("ghost", 50) == -1;
    enter("a", 0);
    leave("a", 1);
    assert leave("a", 2) == -1;
}

test "occupancy per level and total" {
    root spawn AddLevel(number=1, spots=1);
    root spawn AddLevel(number=2, spots=3);
    root spawn AddLevel(number=3, spots=3);
    for p in ["a", "b", "c"] {
        enter(p, 0);
    }
    w = root spawn Occupancy();
    assert len(w.reports) == 1;
    assert w.reports[0] == {1: 1, 2: 2, 3: 0};
    assert w.total == 3;
}

test "occupancy of an empty garage" {
    w = root spawn Occupancy();
    assert len(w.reports[0]) == 0;
    assert w.total == 0;
}
