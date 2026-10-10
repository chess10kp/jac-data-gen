import from tram { Stop, Track, FastestTime, ReachableWithin }

def build -> dict[str, Stop] {
    s: dict[str, Stop] = {};
    for n in ["Harbor", "Market", "Museum", "Park", "Station", "Zoo", "Depot"] {
        s[n] = Stop(name=n);
    }
    s["Harbor"] +>:Track(minutes=4):+> s["Market"];
    s["Market"] +>:Track(minutes=4):+> s["Harbor"];
    s["Market"] +>:Track(minutes=10):+> s["Station"];
    s["Market"] +>:Track(minutes=3):+> s["Museum"];
    s["Museum"] +>:Track(minutes=2):+> s["Park"];
    s["Park"] +>:Track(minutes=2):+> s["Station"];
    s["Station"] +>:Track(minutes=6):+> s["Zoo"];
    s["Zoo"] +>:Track(minutes=1):+> s["Market"];
    s["Harbor"] +>:Track(minutes=30):+> s["Zoo"];
    # Depot only has an outgoing track: unreachable from everywhere else
    s["Depot"] +>:Track(minutes=1):+> s["Harbor"];
    return s;
}

test "fastest time takes cheapest route" {
    s = build();
    assert (s["Harbor"] spawn FastestTime(target="Station")).reports[0] == 11;
    assert (s["Harbor"] spawn FastestTime(target="Zoo")).reports[0] == 17;
    assert (s["Zoo"] spawn FastestTime(target="Harbor")).reports[0] == 5;
    assert (s["Harbor"] spawn FastestTime(target="Market")).reports[0] == 4;
}

test "fastest time edge cases" {
    s = build();
    assert (s["Harbor"] spawn FastestTime(target="Depot")).reports[0] == -1;
    assert (s["Harbor"] spawn FastestTime(target="Harbor")).reports[0] == 0;
    assert (s["Depot"] spawn FastestTime(target="Zoo")).reports[0] == 18;
}

test "reachable within budget" {
    s = build();
    assert list((s["Harbor"] spawn ReachableWithin(budget=9)).reports[0]) == ["Market", "Museum", "Park"];
    assert list((s["Harbor"] spawn ReachableWithin(budget=11)).reports[0]) == ["Market", "Museum", "Park", "Station"];
    assert len((s["Harbor"] spawn ReachableWithin(budget=3)).reports[0]) == 0;
    assert list((s["Station"] spawn ReachableWithin(budget=100)).reports[0]) == ["Harbor", "Market", "Museum", "Park", "Zoo"];
}

test "walkers report once" {
    s = build();
    assert len((s["Harbor"] spawn FastestTime(target="Zoo")).reports) == 1;
    assert len((s["Harbor"] spawn ReachableWithin(budget=20)).reports) == 1;
}
