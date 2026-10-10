import from main { Vehicle, FillUp, find_vehicle, fills_of, AddVehicle, RecordFill, Economy }

def fill(p: str, odo: int, l: float) -> dict[str, any] {
    w = root spawn RecordFill(plate=p, odometer=odo, liters=l);
    assert len(w.reports) == 1;
    return w.reports[0];
}

def econ(p: str) -> float {
    w = root spawn Economy(plate=p);
    assert len(w.reports) == 1;
    return w.reports[0];
}

test "adding a vehicle stores the plate upper-cased once" {
    v = (root spawn AddVehicle(plate="ab12cd")).reports[0];
    assert v.plate == "AB12CD";
    again = (root spawn AddVehicle(plate="AB12cd")).reports[0];
    assert again == v;
    assert len([root -->[?:Vehicle]]) == 1;
}

test "find_vehicle ignores case and returns None for strangers" {
    root spawn AddVehicle(plate="xy1");
    assert find_vehicle("XY1") is not None;
    assert [v.plate for v in [root -->[?:Vehicle]]] == ["XY1"];
    assert find_vehicle("zz9") is None;
}

test "recording fills" {
    root spawn AddVehicle(plate="car1");
    assert fill("CAR1", 1000, 30.0)["ok"] == True;
    assert fill("car1", 1400, 28.0)["ok"] == True;
    v = [root -->[?:Vehicle]][0];
    assert [f.odometer for f in fills_of(v)] == [1000, 1400];
}

test "odometer must strictly increase" {
    root spawn AddVehicle(plate="car1");
    fill("car1", 1000, 30.0);
    same = fill("car1", 1000, 5.0);
    assert same["ok"] == False;
    assert "1000" in same["error"];
    back = fill("car1", 999, 5.0);
    assert back["ok"] == False;
    assert fill("car1", 1001, 5.0)["ok"] == True;
    assert len(fills_of([root -->[?:Vehicle]][0])) == 2;
}

test "unknown vehicle cannot be filled" {
    r = fill("nobody", 10, 1.0);
    assert r["ok"] == False;
    assert r["error"] == "unknown vehicle NOBODY";
    assert len([root -->[?:FillUp]]) == 0;
}

test "economy needs two fills" {
    root spawn AddVehicle(plate="car1");
    assert econ("car1") == 0.0;
    fill("car1", 500, 40.0);
    assert econ("car1") == 0.0;
}

test "economy ignores the first fill's litres" {
    root spawn AddVehicle(plate="car1");
    fill("car1", 1000, 99.0);
    fill("car1", 1400, 30.0);
    assert abs(econ("car1") - 7.5) < 1e-9;
    fill("car1", 2000, 42.0);
    assert abs(econ("CAR1") - 7.2) < 1e-9;
}

test "economy is rounded to two decimals" {
    root spawn AddVehicle(plate="car1");
    fill("car1", 0, 10.0);
    fill("car1", 300, 20.0);
    assert econ("car1") == 6.67;
}

test "economy for unknown plate is zero" {
    assert econ("ghost") == 0.0;
}

test "vehicles do not share fills" {
    root spawn AddVehicle(plate="a");
    root spawn AddVehicle(plate="b");
    fill("a", 0, 1.0);
    fill("a", 100, 5.0);
    fill("b", 0, 1.0);
    fill("b", 100, 10.0);
    assert abs(econ("a") - 5.0) < 1e-9;
    assert abs(econ("b") - 10.0) < 1e-9;
}
