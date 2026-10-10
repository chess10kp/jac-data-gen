import from panel { breaker, outlet, plug }
import from load { PanelLoad }

test "uses the given voltage and a strict threshold" {
    a = breaker("dryer", 10);
    plug(outlet(a, "laundry"), "dryer", 2000, True);
    w = root spawn PanelLoad(volts=240.0);
    assert w.loads["dryer"] == 8.33;
    assert w.reports[0] == ["dryer"];
    at = breaker("garage", 10);
    plug(outlet(at, "garage"), "saw", 960, True);
    w2 = root spawn PanelLoad();
    assert w2.loads["garage"] == 8.0;
    assert "garage" not in w2.reports[0];
}
