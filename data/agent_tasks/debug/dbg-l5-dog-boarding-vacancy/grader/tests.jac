import tempfile;
import from jaclang.testing.testing { JacTestClient }

def open_client -> JacTestClient {
    c = JacTestClient.from_file("app.jac", base_path=tempfile.mkdtemp());
    c.register_user("kennel", "password123");
    return c;
}

def walk(c: JacTestClient, name: str, body: dict[str, any]) -> any {
    resp = c.post("/walker/" + name, json=body);
    assert resp.status_code == 200, f"{name}: {resp.status_code} {resp.text}";
    return resp.json()["data"]["reports"][0];
}

def runs(c: JacTestClient, spec: list[tuple[str, str]]) {
    for (code, size) in spec {
        assert c.post("/function/add_run", json={"code": code, "size": size}).status_code == 200;
    }
}

def book(c: JacTestClient, dog: str, size: str, start: int, nights: int) -> any {
    return walk(c, "book_stay", {"dog": dog, "size": size, "start": start, "nights": nights});
}

test "validation" {
    c = open_client();
    try {
        runs(c, [("S1", "SMALL")]);
        assert book(c, "rex", "HUGE", 1, 0)["reason"] == "bad size";
        assert book(c, "rex", "SMALL", 1, 0)["reason"] == "bad dates";
        assert book(c, "rex", "LARGE", 1, 2)["reason"] == "no vacancy";
    } finally {
        c.close();
    }
}

test "smallest fitting size then lowest code" {
    c = open_client();
    try {
        runs(c, [("L1", "LARGE"), ("M2", "MEDIUM"), ("M1", "MEDIUM"), ("S1", "SMALL")]);
        assert book(c, "bo", "MEDIUM", 1, 2)["run"] == "M1";
        assert book(c, "cy", "MEDIUM", 1, 2)["run"] == "M2";
        assert book(c, "di", "MEDIUM", 2, 1)["run"] == "L1";
        assert book(c, "ed", "SMALL", 1, 5)["run"] == "S1";
        assert book(c, "fy", "SMALL", 3, 1)["run"] == "M1";
    } finally {
        c.close();
    }
}

test "back to back stays do not overlap" {
    c = open_client();
    try {
        runs(c, [("S1", "SMALL")]);
        assert book(c, "a", "SMALL", 10, 3)["ok"] == True;
        assert book(c, "b", "SMALL", 13, 2)["run"] == "S1";
        assert book(c, "c", "SMALL", 9, 1)["run"] == "S1";
        assert book(c, "d", "SMALL", 12, 1)["reason"] == "no vacancy";
    } finally {
        c.close();
    }
}

test "occupancy covers every night of a stay" {
    c = open_client();
    try {
        runs(c, [("S1", "SMALL"), ("S2", "SMALL")]);
        book(c, "zip", "SMALL", 5, 3);
        book(c, "ace", "SMALL", 7, 1);
        assert walk(c, "occupancy", {"night": 7}) == ["S1:zip", "S2:ace"];
        assert walk(c, "occupancy", {"night": 5}) == ["S1:zip"];
        assert len(walk(c, "occupancy", {"night": 8})) == 0;
    } finally {
        c.close();
    }
}

test "check out removes all stays of the dog and frees runs" {
    c = open_client();
    try {
        runs(c, [("S1", "SMALL"), ("L1", "LARGE")]);
        book(c, "rex", "SMALL", 1, 2);
        book(c, "rex", "LARGE", 1, 2);
        book(c, "max", "SMALL", 5, 1);
        assert walk(c, "check_out", {"dog": "rex"}) == 2;
        assert walk(c, "check_out", {"dog": "rex"}) == 0;
        assert book(c, "new", "LARGE", 1, 2)["run"] == "L1";
    } finally {
        c.close();
    }
}

test "vacancy per size for a period" {
    c = open_client();
    try {
        runs(c, [("S1", "SMALL"), ("S2", "SMALL"), ("M1", "MEDIUM")]);
        book(c, "a", "SMALL", 3, 2);
        v = walk(c, "vacancy", {"start": 4, "nights": 3});
        assert v == {"SMALL": 1, "MEDIUM": 1, "LARGE": 0};
        v2 = walk(c, "vacancy", {"start": 5, "nights": 1});
        assert v2 == {"SMALL": 2, "MEDIUM": 1, "LARGE": 0};
    } finally {
        c.close();
    }
}
