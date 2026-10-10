import from app { Vehicle, Sailing, Booking, Holds, add_sailing, book, cancel, manifest, day_summary }

def bk(s: str, ref: str, v: str, p: int) -> dict[str, any] {
    w = root spawn book(sailing=s, ref=ref, vehicle=v, passengers=p);
    assert len(w.reports) == 1;
    return w.reports[0];
}

def man(s: str) -> dict[str, any] {
    return (root spawn manifest(sailing=s)).reports[0];
}

test "booking usage helpers" {
    assert Booking(ref="a", vehicle=Vehicle.VAN, passengers=3).car_use() == 2;
    assert Booking(ref="b", vehicle=Vehicle.CAR, passengers=3).car_use() == 1;
    assert Booking(ref="c", vehicle=Vehicle.FOOT, passengers=3).car_use() == 0;
    assert Booking(ref="d", vehicle=Vehicle.FOOT, passengers=3).foot_use() == 3;
    assert Booking(ref="e", vehicle=Vehicle.CAR, passengers=3).foot_use() == 0;
}

test "simple booking succeeds and appears on the manifest" {
    add_sailing("S1", 1, 2, 2);
    r = bk("S1", "r1", "CAR", 4);
    assert r["ok"] == True;
    assert r["ref"] == "r1";
    m = man("S1");
    assert m["cars"] == 1;
    assert m["foot"] == 0;
    assert m["refs"] == ["r1"];
}

test "unknown sailing is checked first" {
    add_sailing("S1", 1, 2, 2);
    bk("S1", "r1", "CAR", 1);
    assert bk("NOPE", "r1", "BIKE", 1)["reason"] == "unknown sailing";
}

test "duplicate ref before bad vehicle, across sailings" {
    add_sailing("S1", 1, 2, 2);
    add_sailing("S2", 1, 2, 2);
    bk("S1", "r1", "CAR", 1);
    assert bk("S2", "r1", "CAR", 1)["reason"] == "duplicate ref";
    assert bk("S2", "r1", "BIKE", 1)["reason"] == "duplicate ref";
}

test "vehicle names are exact" {
    add_sailing("S1", 5, 5, 5);
    assert bk("S1", "x", "BIKE", 1)["reason"] == "bad vehicle";
    assert bk("S1", "y", "van", 1)["reason"] == "bad vehicle";
    assert bk("S1", "z", "VAN", 1)["ok"] == True;
}

test "van takes two lanes" {
    add_sailing("S1", 1, 3, 0);
    assert bk("S1", "v1", "VAN", 1)["ok"] == True;
    assert bk("S1", "v2", "VAN", 1)["reason"] == "sold out";
    assert bk("S1", "c1", "CAR", 1)["ok"] == True;
    assert bk("S1", "c2", "CAR", 1)["reason"] == "sold out";
    assert man("S1")["cars"] == 3;
}

test "foot seats count passengers and can be filled exactly" {
    add_sailing("S1", 1, 0, 6);
    assert bk("S1", "f1", "FOOT", 4)["ok"] == True;
    assert bk("S1", "f2", "FOOT", 3)["reason"] == "sold out";
    assert bk("S1", "f3", "FOOT", 2)["ok"] == True;
    assert man("S1")["foot"] == 6;
    assert bk("S1", "f4", "FOOT", 1)["reason"] == "sold out";
}

test "car passengers do not use foot seats" {
    add_sailing("S1", 1, 1, 0);
    assert bk("S1", "c", "CAR", 5)["ok"] == True;
    assert man("S1")["foot"] == 0;
}

test "cancel removes the booking and frees space" {
    add_sailing("S1", 1, 1, 0);
    bk("S1", "a", "CAR", 1);
    assert bk("S1", "b", "CAR", 1)["reason"] == "sold out";
    assert (root spawn cancel(ref="a")).reports[0]["ok"] == True;
    assert (root spawn cancel(ref="a")).reports[0]["ok"] == False;
    assert bk("S1", "b", "CAR", 1)["ok"] == True;
    assert man("S1")["refs"] == ["b"];
}

test "cancel of an unknown ref" {
    add_sailing("S1", 1, 1, 1);
    assert (root spawn cancel(ref="ghost")).reports[0]["ok"] == False;
}

test "manifest refs sorted, unknown sailing is empty" {
    add_sailing("S1", 1, 9, 9);
    bk("S1", "m", "CAR", 1);
    bk("S1", "b", "FOOT", 2);
    bk("S1", "x", "VAN", 1);
    m = man("S1");
    assert m["refs"] == ["b", "m", "x"];
    assert m["cars"] == 3;
    assert m["foot"] == 2;
    e = man("NONE");
    assert e["cars"] == 0;
    assert e["foot"] == 0;
    assert len(e["refs"]) == 0;
}

test "day summary only includes that day, sorted by code" {
    add_sailing("PM", 4, 5, 20);
    add_sailing("AM", 4, 5, 20);
    add_sailing("XX", 5, 5, 20);
    bk("PM", "v", "VAN", 1);
    bk("AM", "f", "FOOT", 7);
    bk("XX", "c", "CAR", 1);
    w = root spawn day_summary(day=4);
    assert len(w.reports) == 1;
    rows = w.reports[0];
    assert [r["code"] for r in rows] == ["AM", "PM"];
    assert rows[0]["free_car"] == 5;
    assert rows[0]["free_foot"] == 13;
    assert rows[1]["free_car"] == 3;
    assert rows[1]["free_foot"] == 20;
}
