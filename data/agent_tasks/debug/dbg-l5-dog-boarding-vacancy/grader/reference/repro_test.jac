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

test "back to back and smallest fitting run" {
    c = open_client();
    try {
        for (code, size) in [("L1", "LARGE"), ("M1", "MEDIUM"), ("S1", "SMALL")] {
            fn(c, "add_run", {"code": code, "size": size});
        }
        assert walk(c, "book_stay", {"dog": "rex", "size": "SMALL", "start": 10, "nights": 3})["run"] == "S1";
        assert walk(c, "book_stay", {"dog": "ivy", "size": "SMALL", "start": 13, "nights": 2})["run"] == "S1";
        assert walk(c, "book_stay", {"dog": "bo", "size": "MEDIUM", "start": 1, "nights": 2})["run"] == "M1";
    } finally {
        c.close();
    }
}
