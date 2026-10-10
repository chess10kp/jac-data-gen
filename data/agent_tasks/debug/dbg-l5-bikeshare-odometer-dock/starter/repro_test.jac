import tempfile;
import from jaclang.testing.testing { JacTestClient }

def open_client -> JacTestClient {
    c = JacTestClient.from_file("app.jac", base_path=tempfile.mkdtemp());
    c.register_user("repro", "password123");
    return c;
}

def walk(c: JacTestClient, name: str, body: dict[str, any]) -> any {
    resp = c.post("/walker/" + name, json=body);
    assert resp.status_code == 200, f"{name}: {resp.status_code} {resp.text}";
    return resp.json()["data"]["reports"][0];
}

def fn(c: JacTestClient, name: str, body: dict[str, any]) -> any {
    resp = c.post("/function/" + name, json=body);
    assert resp.status_code == 200, f"{name}: {resp.status_code} {resp.text}";
    return resp.json()["data"]["result"];
}

test "odometer accumulates and full station refuses" {
    c = open_client();
    try {
        fn(c, "add_station", {"code": "S1", "capacity": 3});
        fn(c, "add_station", {"code": "S2", "capacity": 1});
        fn(c, "add_bike", {"station": "S1", "serial": "A-10", "km": 10.0});
        fn(c, "add_bike", {"station": "S1", "serial": "B-11", "km": 11.0});
        walk(c, "rent_bike", {"station": "S1", "rider": "kim", "minute": 1});
        walk(c, "return_bike", {"station": "S1", "rider": "kim", "km": 4.5});
        assert walk(c, "rent_bike", {"station": "S1", "rider": "lee", "minute": 2})["bike"] == "B-11";
        assert walk(c, "return_bike", {"station": "S2", "rider": "lee", "km": 1.0})["ok"] == True;
        walk(c, "rent_bike", {"station": "S1", "rider": "kim", "minute": 3});
        assert walk(c, "return_bike", {"station": "S2", "rider": "kim", "km": 1.0})["reason"] == "station full";
    } finally {
        c.close();
    }
}
