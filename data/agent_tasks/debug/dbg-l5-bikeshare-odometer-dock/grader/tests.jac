import tempfile;
import from jaclang.testing.testing { JacTestClient }

def open_client -> JacTestClient {
    c = JacTestClient.from_file("app.jac", base_path=tempfile.mkdtemp());
    c.register_user("operator", "password123");
    return c;
}

def walk(c: JacTestClient, name: str, body: dict[str, any]) -> any {
    resp = c.post("/walker/" + name, json=body);
    assert resp.status_code == 200, f"{name}: {resp.status_code} {resp.text}";
    return resp.json()["data"]["reports"][0];
}

def fn(c: JacTestClient, name: str, body: dict[str, any]) -> any {
    resp = c.post("/function/" + name, json=body);
    assert resp.status_code == 200;
    return resp.json()["data"]["result"];
}

def setup(c: JacTestClient) {
    fn(c, "add_station", {"code": "S1", "capacity": 3});
    fn(c, "add_station", {"code": "S2", "capacity": 1});
    fn(c, "add_bike", {"station": "S1", "serial": "B-30", "km": 30.0});
    fn(c, "add_bike", {"station": "S1", "serial": "B-10", "km": 10.0});
    fn(c, "add_bike", {"station": "S1", "serial": "A-10", "km": 10.0});
}

test "rent hands out least worn bike, ties by serial" {
    c = open_client();
    try {
        setup(c);
        r = walk(c, "rent_bike", {"station": "S1", "rider": "kim", "minute": 5});
        assert r["ok"] == True;
        assert r["bike"] == "A-10";
        r2 = walk(c, "rent_bike", {"station": "S1", "rider": "lee", "minute": 6});
        assert r2["bike"] == "B-10";
    } finally {
        c.close();
    }
}

test "rent errors in order" {
    c = open_client();
    try {
        setup(c);
        assert walk(c, "rent_bike", {"station": "NOPE", "rider": "kim", "minute": 1})["reason"] == "unknown station";
        assert walk(c, "rent_bike", {"station": "S2", "rider": "kim", "minute": 1})["reason"] == "no bikes";
        walk(c, "rent_bike", {"station": "S1", "rider": "kim", "minute": 1});
        again = walk(c, "rent_bike", {"station": "S1", "rider": "kim", "minute": 2});
        assert again["ok"] == False;
        assert again["reason"] == "already riding";
        busy_empty = walk(c, "rent_bike", {"station": "S2", "rider": "kim", "minute": 2});
        assert busy_empty["reason"] == "already riding";
    } finally {
        c.close();
    }
}

test "status reflects rentals and is sorted" {
    c = open_client();
    try {
        fn(c, "add_station", {"code": "Z9", "capacity": 2});
        setup(c);
        walk(c, "rent_bike", {"station": "S1", "rider": "kim", "minute": 1});
        st = walk(c, "network_status", {});
        assert [s["code"] for s in st] == ["S1", "S2", "Z9"];
        assert st[0]["bikes"] == 2;
        assert st[0]["free"] == 1;
        assert st[1]["bikes"] == 0;
        assert st[2]["free"] == 2;
    } finally {
        c.close();
    }
}

test "return docks bike, adds km, frees rider" {
    c = open_client();
    try {
        setup(c);
        walk(c, "rent_bike", {"station": "S1", "rider": "kim", "minute": 1});
        r = walk(c, "return_bike", {"station": "S2", "rider": "kim", "km": 4.5});
        assert r["ok"] == True;
        assert r["bike"] == "A-10";
        st = walk(c, "network_status", {});
        assert st[1]["bikes"] == 1;
        assert st[0]["bikes"] == 2;
        again = walk(c, "rent_bike", {"station": "S1", "rider": "kim", "minute": 9});
        assert again["bike"] == "B-10";
        walk(c, "return_bike", {"station": "S1", "rider": "kim", "km": 1.0});
        walk(c, "rent_bike", {"station": "S2", "rider": "ann", "minute": 10});
        walk(c, "return_bike", {"station": "S1", "rider": "ann", "km": 0.0});
        third = walk(c, "rent_bike", {"station": "S1", "rider": "bo", "minute": 11});
        assert third["bike"] == "B-10";
    } finally {
        c.close();
    }
}

test "return errors" {
    c = open_client();
    try {
        setup(c);
        assert walk(c, "return_bike", {"station": "S1", "rider": "ghost", "km": 1.0})["reason"] == "not riding";
        walk(c, "rent_bike", {"station": "S1", "rider": "kim", "minute": 1});
        walk(c, "rent_bike", {"station": "S1", "rider": "lee", "minute": 1});
        assert walk(c, "return_bike", {"station": "XX", "rider": "kim", "km": 1.0})["reason"] == "unknown station";
        assert walk(c, "return_bike", {"station": "S2", "rider": "kim", "km": 1.0})["ok"] == True;
        full = walk(c, "return_bike", {"station": "S2", "rider": "lee", "km": 1.0});
        assert full["reason"] == "station full";
        ok = walk(c, "return_bike", {"station": "S1", "rider": "lee", "km": 1.0});
        assert ok["ok"] == True;
    } finally {
        c.close();
    }
}
