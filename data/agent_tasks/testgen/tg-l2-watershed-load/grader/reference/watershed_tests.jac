import from watershed { Reach, Station, FlowsInto, Samples, connect_reach, UpstreamLoad }

def reach(name: str, kg: float) -> Reach {
    r = Reach(name=name, load_kg=kg);
    root ++> r;
    return r;
}

def gauge(r: Reach) -> Station {
    s = Station(code="G-" + r.name);
    root ++> s;
    s +>:Samples():+> r;
    return s;
}

test "station walker runs" {
    w = gauge(reach("r", 1.0)) spawn UpstreamLoad();
    assert len(w.reports) == 1;
    assert w.reports[0] == ["r"];
    assert w.total_kg == 1.0;
}

test "station sampling nothing reports empty" {
    s = Station(code="none");
    root ++> s;
    w = s spawn UpstreamLoad();
    assert len(w.reports) == 1;
    assert len(w.reports[0]) == 0;
    assert w.total_kg == 0.0;
}

test "connect_reach builds a downstream edge" {
    a = reach("a", 0.0);
    b = reach("b", 0.0);
    connect_reach(a, b, True);
    assert [x.name for x in [a ->:FlowsInto:->]] == ["b"];
    assert [edge a ->:FlowsInto:->][0].seasonal == True;
}

test "downstream reaches are not included" {
    up = reach("up", 1.0);
    mid = reach("mid", 2.0);
    down = reach("down", 4.0);
    connect_reach(up, mid, False);
    connect_reach(mid, down, False);
    w = gauge(mid) spawn UpstreamLoad();
    assert w.reports[0] == ["mid", "up"];
    assert w.total_kg == 3.0;
}

test "whole chain upstream is summed" {
    a = reach("a", 1.0);
    b = reach("b", 2.0);
    c = reach("c", 4.0);
    d = reach("d", 8.0);
    connect_reach(a, b, False);
    connect_reach(b, c, False);
    connect_reach(c, d, False);
    w = gauge(d) spawn UpstreamLoad();
    assert w.reports[0] == ["a", "b", "c", "d"];
    assert w.total_kg == 15.0;
}

test "tributaries joining are all counted" {
    trunk = reach("trunk", 1.0);
    t1 = reach("t1", 2.0);
    t2 = reach("t2", 3.0);
    connect_reach(t1, trunk, False);
    connect_reach(t2, trunk, False);
    w = gauge(trunk) spawn UpstreamLoad();
    assert w.reports[0] == ["t1", "t2", "trunk"];
    assert w.total_kg == 6.0;
}

test "braided channel reaches are counted once" {
    src = reach("src", 100.0);
    l = reach("l", 1.0);
    r = reach("r", 1.0);
    out = reach("out", 1.0);
    connect_reach(src, l, False);
    connect_reach(src, r, False);
    connect_reach(l, out, False);
    connect_reach(r, out, False);
    w = gauge(out) spawn UpstreamLoad();
    assert w.reports[0] == ["l", "out", "r", "src"];
    assert w.total_kg == 103.0;
    assert len(w.names) == 4;
}

test "wet season follows seasonal channels" {
    hill = reach("hill", 5.0);
    town = reach("town", 1.0);
    connect_reach(hill, town, True);
    w = gauge(town) spawn UpstreamLoad();
    assert w.reports[0] == ["hill", "town"];
    assert w.total_kg == 6.0;
}

test "dry season skips seasonal channels and everything behind them" {
    far = reach("far", 7.0);
    gully = reach("gully", 3.0);
    spring = reach("spring", 2.0);
    town = reach("town", 1.0);
    connect_reach(far, gully, False);
    connect_reach(gully, town, True);
    connect_reach(spring, town, False);
    w = gauge(town) spawn UpstreamLoad(dry_season=True);
    assert w.reports[0] == ["spring", "town"];
    assert w.total_kg == 3.0;
}

test "dry season still reaches a source through a permanent detour" {
    s = reach("s", 1.0);
    via = reach("via", 2.0);
    o = reach("o", 4.0);
    connect_reach(s, o, True);
    connect_reach(s, via, False);
    connect_reach(via, o, False);
    w = gauge(o) spawn UpstreamLoad(dry_season=True);
    assert w.reports[0] == ["o", "s", "via"];
    assert w.total_kg == 7.0;
}
