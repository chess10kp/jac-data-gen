import from panel { Breaker, Outlet, Appliance, breaker, outlet, plug }
import from load { PanelLoad }
import from reports { ListAppliances }

test "load per breaker from on appliances" {
    b1 = breaker("K1", 20);
    b2 = breaker("K2", 15);
    o1 = outlet(b1, "kitchen");
    o2 = outlet(b1, "dining");
    o3 = outlet(b2, "bedroom");
    plug(o1, "kettle", 1200, True);
    plug(o2, "lamp", 60, True);
    plug(o2, "heater", 1500, False);
    w = root spawn PanelLoad();
    assert w.loads == {"K1": 10.5, "K2": 0.0};
    assert len(w.reports) == 1;
    assert len(w.reports[0]) == 0;
}

test "overload is strictly above eighty percent" {
    at = breaker("AT", 10);
    over = breaker("OVER", 10);
    plug(outlet(at, "garage"), "saw", 960, True);
    plug(outlet(over, "shed"), "welder", 972, True);
    w = root spawn PanelLoad();
    assert w.loads["AT"] == 8.0;
    assert w.loads["OVER"] == 8.1;
    assert w.reports[0] == ["OVER"];
}

test "voltage parameter and sorted labels" {
    a = breaker("Zeta", 10);
    b = breaker("Alpha", 10);
    plug(outlet(a, "x"), "dryer", 2000, True);
    plug(outlet(b, "y"), "oven", 2000, True);
    w = root spawn PanelLoad(volts=240.0);
    assert w.loads == {"Zeta": 8.33, "Alpha": 8.33};
    assert w.reports[0] == ["Alpha", "Zeta"];
    w2 = root spawn PanelLoad(volts=1000.0);
    assert len(w2.reports[0]) == 0;
}

test "inventory lines carry breaker label" {
    b1 = breaker("K1", 20);
    b2 = breaker("K2", 15);
    plug(outlet(b1, "kitchen"), "toaster", 800, False);
    plug(outlet(b2, "attic"), "fan", 40, True);
    w = root spawn ListAppliances();
    assert w.reports[0] == ["K1/kitchen: toaster", "K2/attic: fan"];
}
