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

test "two criteria from one judge both count, empty track lists all" {
    c = open_client();
    try {
        fn(c, "register_team", {"name": "Otters", "track": "climate"});
        fn(c, "register_team", {"name": "Badgers", "track": "health"});
        fn(c, "add_judge", {"name": "Ines"});
        walk(c, "score_team", {"judge": "Ines", "team": "Otters", "criterion": "IMPACT", "points": 8});
        walk(c, "score_team", {"judge": "Ines", "team": "Otters", "criterion": "CRAFT", "points": 7});
        board = walk(c, "leaderboard", {"track": ""});
        assert [r["team"] for r in board] == ["Otters", "Badgers"];
        assert board[0]["score"] == 15.0;
    } finally {
        c.close();
    }
}
