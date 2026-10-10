import uuid;
import from main { set_capacity, park, leave, occupancy }

def get(x: any, k: str) -> any {
    return x[k] if isinstance(x, dict) else getattr(x, k);
}

def is_err(x: any) -> bool {
    return isinstance(x, dict) and "error" in x;
}

test "park leave and fees" {
    set_capacity(spots=1000);
    p = "ab" + uuid.uuid4().hex[:5];
    r = park(plate=p, at="08:00");
    assert get(r, "plate") == p.upper() and get(r, "entered") == "08:00";
    assert p.upper() in list(get(occupancy(), "plates"));
    l = leave(plate=p.upper(), at="09:01");
    assert get(l, "minutes") == 61 and abs(get(l, "fee") - 4.0) < 1e-9;
    assert p.upper() not in list(get(occupancy(), "plates"));
    q = "cd" + uuid.uuid4().hex[:5];
    park(plate=q, at="10:00");
    assert abs(get(leave(plate=q, at="10:30"), "fee")) < 1e-9;
    park(plate=q, at="11:00");
    assert abs(get(leave(plate=q, at="11:31"), "fee") - 2.0) < 1e-9;
}

test "errors" {
    set_capacity(spots=1000);
    p = "ef" + uuid.uuid4().hex[:5];
    park(plate=p, at="07:00");
    assert is_err(park(plate=p.lower(), at="07:05"));
    assert is_err(leave(plate=p, at="06:59"));
    assert is_err(leave(plate="zz" + p, at="08:00"));
    assert is_err(park(plate="gh" + p, at="7:00"));
    assert is_err(park(plate="gh" + p, at="25:00"));
    assert is_err(set_capacity(spots=0));
    assert get(leave(plate=p, at="07:20"), "minutes") == 20;
}

test "capacity and occupancy counts" {
    o = occupancy();
    base = get(o, "occupied");
    set_capacity(spots=base + 1);
    assert get(occupancy(), "free") == 1;
    p = "ij" + uuid.uuid4().hex[:5];
    q = "kl" + uuid.uuid4().hex[:5];
    assert not is_err(park(plate=p, at="12:00"));
    assert is_err(park(plate=q, at="12:00"));
    o2 = occupancy();
    assert get(o2, "occupied") == base + 1 and get(o2, "free") == 0 and get(o2, "capacity") == base + 1;
    if base + 1 > 1 {
        assert is_err(set_capacity(spots=base));
    }
    leave(plate=p, at="12:10");
    set_capacity(spots=1000);
}
