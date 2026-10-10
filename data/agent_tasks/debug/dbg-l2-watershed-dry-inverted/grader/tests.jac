import from watershed { Reach, Station, FlowsInto, Samples, connect_reach, UpstreamLoad }

def station_on(r: Reach) -> Station {
    s = Station(code="S-" + r.name);
    root ++> s;
    s +>:Samples():+> r;
    return s;
}

test "single reach counts itself" {
    r = Reach(name="mouth", load_kg=2.5);
    root ++> r;
    w = station_on(r) spawn UpstreamLoad();
    assert len(w.reports) == 1;
    assert w.reports[0] == ["mouth"];
    assert w.total_kg == 2.5;
}

test "unlinked station reports nothing" {
    s = Station(code="lonely");
    root ++> s;
    w = s spawn UpstreamLoad();
    assert len(w.reports[0]) == 0;
    assert w.total_kg == 0.0;
}

test "follows flow upstream only" {
    a = Reach(name="alpha", load_kg=1.0);
    b = Reach(name="beta", load_kg=2.0);
    c = Reach(name="gamma", load_kg=4.0);
    d = Reach(name="delta", load_kg=8.0);
    root ++> a;
    connect_reach(a, b, False);
    connect_reach(b, c, False);
    connect_reach(c, d, False);
    w = station_on(b) spawn UpstreamLoad();
    assert w.reports[0] == ["alpha", "beta"];
    assert w.total_kg == 3.0;
}

test "braided channels count each reach once" {
    top = Reach(name="top", load_kg=10.0);
    left = Reach(name="left", load_kg=1.0);
    right = Reach(name="right", load_kg=1.0);
    low = Reach(name="low", load_kg=0.5);
    root ++> top;
    connect_reach(top, left, False);
    connect_reach(top, right, False);
    connect_reach(left, low, False);
    connect_reach(right, low, False);
    w = station_on(low) spawn UpstreamLoad();
    assert w.reports[0] == ["left", "low", "right", "top"];
    assert w.total_kg == 12.5;
}

test "dry season ignores seasonal channels and what lies beyond" {
    hill = Reach(name="hill", load_kg=5.0);
    gully = Reach(name="gully", load_kg=3.0);
    spring = Reach(name="spring", load_kg=1.0);
    town = Reach(name="town", load_kg=2.0);
    root ++> town;
    connect_reach(hill, gully, False);
    connect_reach(gully, town, True);
    connect_reach(spring, town, False);
    st = station_on(town);
    dry = st spawn UpstreamLoad(dry_season=True);
    assert dry.reports[0] == ["spring", "town"];
    assert dry.total_kg == 3.0;
    wet = st spawn UpstreamLoad(dry_season=False);
    assert wet.reports[0] == ["gully", "hill", "spring", "town"];
    assert wet.total_kg == 11.0;
}

test "reach reachable through a permanent channel still counts in dry season" {
    src = Reach(name="src", load_kg=1.0);
    mid = Reach(name="mid", load_kg=1.0);
    out = Reach(name="out", load_kg=1.0);
    root ++> out;
    connect_reach(src, out, True);
    connect_reach(src, mid, False);
    connect_reach(mid, out, False);
    w = station_on(out) spawn UpstreamLoad(dry_season=True);
    assert w.reports[0] == ["mid", "out", "src"];
    assert w.total_kg == 3.0;
}
