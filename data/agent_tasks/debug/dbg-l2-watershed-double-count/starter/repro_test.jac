import from watershed { Reach, Station, Samples, connect_reach, UpstreamLoad }

test "braided channel counts each reach once" {
    top = Reach(name="top", load_kg=10.0);
    left = Reach(name="left", load_kg=1.0);
    right = Reach(name="right", load_kg=1.0);
    low = Reach(name="low", load_kg=0.5);
    root ++> top;
    connect_reach(top, left, False);
    connect_reach(top, right, False);
    connect_reach(left, low, False);
    connect_reach(right, low, False);
    s = root ++> Station(code="low-ford");
    s +>:Samples():+> low;
    w = s spawn UpstreamLoad();
    assert w.total_kg == 12.5;
}
