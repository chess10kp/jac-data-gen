import from keepers { Lens, Lamp, add_lamp, NightShift }

def find(station: str) -> Lamp {
    return [root -->[?:Lamp, station == station]][0];
}

test "add_lamp attaches a lamp with its fields" {
    add_lamp("north", Lens.FIRST_ORDER, 12.0, 800.0, True);
    l = find("north");
    assert l.lens == Lens.FIRST_ORDER;
    assert l.burn_hours == 12.0;
    assert l.rated_hours == 800.0;
    assert l.lit == True;
}

test "no lamps reports one empty list" {
    w = root spawn NightShift(hours=6.0);
    assert len(w.reports) == 1;
    assert len(w.reports[0]) == 0;
}

test "lit second and third order lamps add hours one to one" {
    add_lamp("s", Lens.SECOND_ORDER, 10.0, 1000.0, True);
    add_lamp("t", Lens.THIRD_ORDER, 20.0, 1000.0, True);
    root spawn NightShift(hours=4.0);
    assert find("s").burn_hours == 14.0;
    assert find("t").burn_hours == 24.0;
}

test "first order lamps add one and a half times" {
    add_lamp("f", Lens.FIRST_ORDER, 2.0, 1000.0, True);
    root spawn NightShift(hours=4.0);
    assert find("f").burn_hours == 8.0;
}

test "unlit lamp is untouched and never due" {
    add_lamp("off", Lens.FIRST_ORDER, 999.0, 1000.0, False);
    w = root spawn NightShift(hours=3.0);
    assert find("off").burn_hours == 999.0;
    assert len(w.reports[0]) == 0;
}

test "due threshold is ninety percent inclusive" {
    add_lamp("under", Lens.THIRD_ORDER, 89.0, 100.0, True);
    add_lamp("exact", Lens.THIRD_ORDER, 89.5, 100.0, True);
    w = root spawn NightShift(hours=0.5);
    assert w.reports[0] == ["exact"];
    assert w.due == ["exact"];
}

test "first order factor can push a lamp over the line" {
    add_lamp("fast", Lens.FIRST_ORDER, 84.0, 100.0, True);
    add_lamp("slow", Lens.SECOND_ORDER, 84.0, 100.0, True);
    w = root spawn NightShift(hours=4.0);
    assert w.reports[0] == ["fast"];
}

test "due list is sorted and reported once" {
    add_lamp("rock", Lens.THIRD_ORDER, 950.0, 1000.0, True);
    add_lamp("bay", Lens.THIRD_ORDER, 950.0, 1000.0, True);
    add_lamp("cove", Lens.THIRD_ORDER, 100.0, 1000.0, True);
    add_lamp("arch", Lens.THIRD_ORDER, 960.0, 1000.0, True);
    w = root spawn NightShift(hours=1.0);
    assert len(w.reports) == 1;
    assert w.reports[0] == ["arch", "bay", "rock"];
}

test "hours accumulate across shifts" {
    add_lamp("pier", Lens.FIRST_ORDER, 0.0, 1000.0, True);
    root spawn NightShift(hours=2.0);
    root spawn NightShift(hours=2.0);
    assert find("pier").burn_hours == 6.0;
}
