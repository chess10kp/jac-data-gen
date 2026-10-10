import tempfile;
import from jaclang.testing.testing { JacTestClient }

def open_client -> JacTestClient {
    c = JacTestClient.from_file("app.jac", base_path=tempfile.mkdtemp());
    c.register_user("purser", "password123");
    return c;
}

def walk(c: JacTestClient, name: str, body: dict[str, any]) -> any {
    resp = c.post("/walker/" + name, json=body);
    assert resp.status_code == 200, f"{name}: {resp.status_code} {resp.text}";
    return resp.json()["data"]["reports"][0];
}

def sailing(c: JacTestClient, code: str, day: int, cars: int, foot: int) {
    assert c.post("/function/add_sailing", json={"code": code, "day": day, "car_slots": cars, "foot_slots": foot}).status_code == 200;
}

def book(c: JacTestClient, s: str, ref: str, v: str, p: int) -> any {
    return walk(c, "book", {"sailing": s, "ref": ref, "vehicle": v, "passengers": p});
}

test "booking errors in order" {
    c = open_client();
    try {
        sailing(c, "AM1", 1, 2, 4);
        assert book(c, "XX", "r1", "CAR", 1)["reason"] == "unknown sailing";
        assert book(c, "AM1", "r1", "CAR", 1)["ok"] == True;
        assert book(c, "XX", "r1", "BOAT", 1)["reason"] == "unknown sailing";
        assert book(c, "AM1", "r1", "BOAT", 1)["reason"] == "duplicate ref";
        assert book(c, "AM1", "r2", "BOAT", 1)["reason"] == "bad vehicle";
        assert book(c, "AM1", "r2", "car", 1)["reason"] == "bad vehicle";
        ok = book(c, "AM1", "r2", "VAN", 3);
        assert ok["reason"] == "sold out";
    } finally {
        c.close();
    }
}

test "deck accounting for cars vans and foot passengers" {
    c = open_client();
    try {
        sailing(c, "AM1", 1, 3, 5);
        assert book(c, "AM1", "v1", "VAN", 4)["ok"];
        assert book(c, "AM1", "c1", "CAR", 5)["ok"];
        assert book(c, "AM1", "c2", "CAR", 1)["reason"] == "sold out";
        assert book(c, "AM1", "f1", "FOOT", 3)["ok"];
        assert book(c, "AM1", "f2", "FOOT", 3)["reason"] == "sold out";
        assert book(c, "AM1", "f3", "FOOT", 2)["ok"];
        m = walk(c, "manifest", {"sailing": "AM1"});
        assert m["cars"] == 3;
        assert m["foot"] == 5;
        assert m["refs"] == ["c1", "f1", "f3", "v1"];
    } finally {
        c.close();
    }
}

test "duplicate refs are checked across sailings" {
    c = open_client();
    try {
        sailing(c, "AM1", 1, 3, 5);
        sailing(c, "PM1", 1, 3, 5);
        book(c, "AM1", "same", "CAR", 1);
        assert book(c, "PM1", "same", "CAR", 1)["reason"] == "duplicate ref";
    } finally {
        c.close();
    }
}

test "cancel frees capacity" {
    c = open_client();
    try {
        sailing(c, "AM1", 1, 1, 1);
        sailing(c, "PM1", 1, 1, 1);
        book(c, "AM1", "a", "CAR", 1);
        book(c, "PM1", "b", "FOOT", 1);
        assert walk(c, "cancel", {"ref": "b"})["ok"] == True;
        assert walk(c, "cancel", {"ref": "b"})["ok"] == False;
        assert walk(c, "cancel", {"ref": "zzz"})["ok"] == False;
        assert book(c, "PM1", "b2", "FOOT", 1)["ok"] == True;
        assert book(c, "AM1", "a2", "CAR", 1)["reason"] == "sold out";
        m = walk(c, "manifest", {"sailing": "PM1"});
        assert m["refs"] == ["b2"];
        empty = walk(c, "manifest", {"sailing": "NONE"});
        assert empty["cars"] == 0;
        assert len(empty["refs"]) == 0;
    } finally {
        c.close();
    }
}

test "day summary per sailing sorted by code" {
    c = open_client();
    try {
        sailing(c, "PM1", 2, 4, 10);
        sailing(c, "AM1", 2, 4, 10);
        sailing(c, "AM9", 3, 4, 10);
        book(c, "PM1", "x", "VAN", 2);
        book(c, "AM1", "y", "FOOT", 6);
        rows = walk(c, "day_summary", {"day": 2});
        assert [r["code"] for r in rows] == ["AM1", "PM1"];
        assert rows[0]["free_car"] == 4;
        assert rows[0]["free_foot"] == 4;
        assert rows[1]["free_car"] == 2;
        assert rows[1]["free_foot"] == 10;
    } finally {
        c.close();
    }
}
