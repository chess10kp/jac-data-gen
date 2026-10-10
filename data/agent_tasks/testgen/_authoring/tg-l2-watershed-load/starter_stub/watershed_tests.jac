import from watershed { Reach, Station, FlowsInto, Samples, connect_reach, UpstreamLoad }

test "station walker runs" {
    r = Reach(name="r", load_kg=1.0);
    root ++> r;
    s = Station(code="s");
    root ++> s;
    s +>:Samples():+> r;
    w = s spawn UpstreamLoad();
    assert len(w.reports) == 1;
}
