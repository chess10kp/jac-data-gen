import uuid;
import from main { AddVehicle, RecordFill, Economy }

def get(x: any, k: str) -> any {
    return x[k] if isinstance(x, dict) else getattr(x, k);
}

def econ(p: str) -> float {
    return (root spawn Economy(plate=p)).reports[0];
}

test "economy over several fills" {
    p = "VAN" + uuid.uuid4().hex[:5].upper();
    root spawn AddVehicle(plate=p);
    assert get((root spawn RecordFill(plate=p, odometer=10000, liters=40.0)).reports[0], "ok") == True;
    assert abs(econ(p)) < 1e-9;
    root spawn RecordFill(plate=p, odometer=10500, liters=42.5);
    assert abs(econ(p) - 8.5) < 1e-9;
    root spawn RecordFill(plate=p, odometer=11100, liters=45.3);
    assert abs(econ(p) - 7.98) < 1e-9;
}

test "plates are case insensitive" {
    p = "abc" + uuid.uuid4().hex[:5];
    root spawn AddVehicle(plate=p);
    root spawn RecordFill(plate=p.upper(), odometer=100, liters=10.0);
    root spawn RecordFill(plate=p, odometer=300, liters=13.0);
    assert abs(econ(p.upper()) - 6.5) < 1e-9;
}

test "rejects bad odometer and unknown plate" {
    p = "VAN" + uuid.uuid4().hex[:5].upper();
    root spawn AddVehicle(plate=p);
    root spawn RecordFill(plate=p, odometer=5000, liters=30.0);
    bad = (root spawn RecordFill(plate=p, odometer=5000, liters=10.0)).reports[0];
    assert get(bad, "ok") == False;
    assert len(str(get(bad, "error"))) > 0;
    worse = (root spawn RecordFill(plate=p, odometer=4000, liters=10.0)).reports[0];
    assert get(worse, "ok") == False;
    ghost = (root spawn RecordFill(plate="GHOST" + p, odometer=10, liters=1.0)).reports[0];
    assert get(ghost, "ok") == False;
    assert abs(econ(p)) < 1e-9;
}

test "unknown vehicle economy is zero" {
    assert abs(econ("NOPE" + uuid.uuid4().hex[:5])) < 1e-9;
}
