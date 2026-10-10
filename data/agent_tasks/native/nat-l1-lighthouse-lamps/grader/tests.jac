import from keepers { Lens, Lamp, add_lamp, NightShift }

def lamp(station: str) -> Lamp {
    return [root -->[?:Lamp, station == station]][0];
}

test "lit lamp accumulates hours on the node" {
    add_lamp("north", Lens.SECOND_ORDER, 100.0, 1000.0, True);
    w = root spawn NightShift(hours=10.0);
    assert lamp("north").burn_hours == 110.0;
    assert len(w.reports) == 1;
    assert len(w.reports[0]) == 0;
}

test "first order lens wears one and a half times faster" {
    add_lamp("cape", Lens.FIRST_ORDER, 0.0, 1000.0, True);
    add_lamp("bay", Lens.THIRD_ORDER, 0.0, 1000.0, True);
    root spawn NightShift(hours=8.0);
    assert lamp("cape").burn_hours == 12.0;
    assert lamp("bay").burn_hours == 8.0;
}

test "unlit lamps neither accumulate nor get reported" {
    add_lamp("dark", Lens.SECOND_ORDER, 950.0, 1000.0, False);
    w = root spawn NightShift(hours=5.0);
    assert lamp("dark").burn_hours == 950.0;
    assert len(w.reports[0]) == 0;
}

test "due at exactly ninety percent, sorted by station" {
    add_lamp("zeta", Lens.THIRD_ORDER, 890.0, 1000.0, True);
    add_lamp("alpha", Lens.THIRD_ORDER, 880.0, 1000.0, True);
    add_lamp("mid", Lens.THIRD_ORDER, 100.0, 1000.0, True);
    w = root spawn NightShift(hours=10.0);
    assert w.reports[0] == ["zeta"];
    w2 = root spawn NightShift(hours=10.0);
    assert w2.reports[0] == ["alpha", "zeta"];
    assert sorted(w2.due) == ["alpha", "zeta"];
}

test "first order factor decides due status" {
    add_lamp("hot", Lens.FIRST_ORDER, 0.0, 100.0, True);
    w = root spawn NightShift(hours=60.0);
    assert w.reports[0] == ["hot"];
    assert lamp("hot").burn_hours == 90.0;
}

test "totals keep adding up over several nights" {
    add_lamp("pier", Lens.SECOND_ORDER, 0.0, 500.0, True);
    root spawn NightShift(hours=7.5);
    root spawn NightShift(hours=7.5);
    root spawn NightShift(hours=5.0);
    assert lamp("pier").burn_hours == 20.0;
}
