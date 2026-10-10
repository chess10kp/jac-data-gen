import tempfile;
import from jaclang.runtimelib.testing { JacTestClient }

def client -> JacTestClient {
    c = JacTestClient.from_file("app.jac", base_path=tempfile.mkdtemp());
    c.register_user("dockops", "password123");
    return c;
}

"""Response body; some server versions wrap it in a {"data": ...} envelope."""
def payload(resp: any) -> dict[str, any] {
    body = resp.json();
    return body["data"] if "data" in body and isinstance(body["data"], dict) else body;
}

def call(c: JacTestClient, name: str, body: dict[str, any]) -> any {
    resp = c.post("/function/" + name, json=body);
    assert resp.status_code == 200, f"{name}: {resp.status_code} {resp.text}";
    return payload(resp)["result"];
}

def walk(c: JacTestClient, name: str, body: dict[str, any]) -> any {
    resp = c.post("/walker/" + name, json=body);
    assert resp.status_code == 200, f"{name}: {resp.status_code} {resp.text}";
    reports = payload(resp)["reports"];
    assert len(reports) == 1;
    return reports[0];
}

def rent(c: JacTestClient, st: str, who: str) -> any {
    return walk(c, "rent_bike", {"station": st, "rider": who, "minute": 1});
}

def ret(c: JacTestClient, st: str, who: str, km: float) -> any {
    return walk(c, "return_bike", {"station": st, "rider": who, "km": km});
}

test "add_bike respects station capacity and unknown stations" {
    c = client();
    try {
        call(c, "add_station", {"code": "A", "capacity": 1});
        assert call(c, "add_bike", {"station": "A", "serial": "b1", "km": 0.0}) == True;
        assert call(c, "add_bike", {"station": "A", "serial": "b2", "km": 0.0}) == False;
        assert call(c, "add_bike", {"station": "Q", "serial": "b3", "km": 0.0}) == False;
    } finally {
        c.close();
    }
}

test "least worn bike first, serial breaks ties" {
    c = client();
    try {
        call(c, "add_station", {"code": "A", "capacity": 5});
        call(c, "add_bike", {"station": "A", "serial": "Z", "km": 3.0});
        call(c, "add_bike", {"station": "A", "serial": "Y", "km": 7.0});
        call(c, "add_bike", {"station": "A", "serial": "C", "km": 3.0});
        r = rent(c, "A", "ann");
        assert r["ok"] == True;
        assert r["bike"] == "C";
        assert rent(c, "A", "bob")["bike"] == "Z";
        assert rent(c, "A", "cy")["bike"] == "Y";
        assert rent(c, "A", "dee")["reason"] == "no bikes";
    } finally {
        c.close();
    }
}

test "rent rejections" {
    c = client();
    try {
        call(c, "add_station", {"code": "A", "capacity": 2});
        call(c, "add_station", {"code": "E", "capacity": 2});
        call(c, "add_bike", {"station": "A", "serial": "b1", "km": 0.0});
        call(c, "add_bike", {"station": "A", "serial": "b2", "km": 0.0});
        bad = rent(c, "nowhere", "ann");
        assert bad["ok"] == False;
        assert bad["reason"] == "unknown station";
        assert rent(c, "E", "ann")["reason"] == "no bikes";
        assert rent(c, "A", "ann")["ok"] == True;
        twice = rent(c, "A", "ann");
        assert twice["ok"] == False;
        assert twice["reason"] == "already riding";
    } finally {
        c.close();
    }
}

test "return rejections" {
    c = client();
    try {
        call(c, "add_station", {"code": "A", "capacity": 1});
        call(c, "add_station", {"code": "F", "capacity": 1});
        call(c, "add_bike", {"station": "A", "serial": "b1", "km": 0.0});
        call(c, "add_bike", {"station": "F", "serial": "b2", "km": 0.0});
        assert ret(c, "A", "nobody", 1.0)["reason"] == "not riding";
        rent(c, "A", "ann");
        assert ret(c, "zzz", "ann", 1.0)["reason"] == "unknown station";
        full = ret(c, "F", "ann", 1.0);
        assert full["ok"] == False;
        assert full["reason"] == "station full";
        ok = ret(c, "A", "ann", 1.0);
        assert ok["ok"] == True;
        assert ok["bike"] == "b1";
        assert ret(c, "A", "ann", 1.0)["reason"] == "not riding";
    } finally {
        c.close();
    }
}

test "returned km counts toward wear" {
    c = client();
    try {
        call(c, "add_station", {"code": "A", "capacity": 3});
        call(c, "add_bike", {"station": "A", "serial": "a", "km": 1.0});
        call(c, "add_bike", {"station": "A", "serial": "b", "km": 2.0});
        assert rent(c, "A", "ann")["bike"] == "a";
        ret(c, "A", "ann", 5.0);
        assert rent(c, "A", "ann")["bike"] == "b";
        ret(c, "A", "ann", 0.5);
        assert rent(c, "A", "bob")["bike"] == "b";
    } finally {
        c.close();
    }
}

test "a rider can rent again after returning" {
    c = client();
    try {
        call(c, "add_station", {"code": "A", "capacity": 2});
        call(c, "add_bike", {"station": "A", "serial": "a", "km": 0.0});
        rent(c, "A", "ann");
        ret(c, "A", "ann", 0.0);
        assert rent(c, "A", "ann")["ok"] == True;
    } finally {
        c.close();
    }
}

test "network status rows sorted by code" {
    c = client();
    try {
        call(c, "add_station", {"code": "M", "capacity": 4});
        call(c, "add_station", {"code": "B", "capacity": 2});
        call(c, "add_bike", {"station": "M", "serial": "1", "km": 0.0});
        call(c, "add_bike", {"station": "M", "serial": "2", "km": 0.0});
        call(c, "add_bike", {"station": "B", "serial": "3", "km": 0.0});
        rent(c, "M", "ann");
        rows = walk(c, "network_status", {});
        assert [r["code"] for r in rows] == ["B", "M"];
        assert rows[0]["bikes"] == 1;
        assert rows[0]["free"] == 1;
        assert rows[1]["bikes"] == 1;
        assert rows[1]["free"] == 3;
        ret(c, "B", "ann", 0.0);
        rows2 = walk(c, "network_status", {});
        assert rows2[0]["bikes"] == 2;
        assert rows2[0]["free"] == 0;
    } finally {
        c.close();
    }
}
