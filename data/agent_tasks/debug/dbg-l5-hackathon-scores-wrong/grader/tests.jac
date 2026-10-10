import tempfile;
import from jaclang.testing.testing { JacTestClient }

def open_client -> JacTestClient {
    c = JacTestClient.from_file("app.jac", base_path=tempfile.mkdtemp());
    c.register_user("organiser", "password123");
    return c;
}

def walk(c: JacTestClient, name: str, body: dict[str, any]) -> any {
    resp = c.post("/walker/" + name, json=body);
    assert resp.status_code == 200, f"{name}: {resp.status_code} {resp.text}";
    return resp.json()["data"]["reports"][0];
}

def fn(c: JacTestClient, name: str, body: dict[str, any]) {
    resp = c.post("/function/" + name, json=body);
    assert resp.status_code == 200;
}

def score(c: JacTestClient, j: str, t: str, crit: str, pts: int) -> any {
    return walk(c, "score_team", {"judge": j, "team": t, "criterion": crit, "points": pts});
}

def seed(c: JacTestClient) {
    fn(c, "register_team", {"name": "Otters", "track": "climate"});
    fn(c, "register_team", {"name": "Badgers", "track": "health"});
    fn(c, "register_team", {"name": "Cranes", "track": "climate"});
    fn(c, "add_judge", {"name": "Ines"});
    fn(c, "add_judge", {"name": "Raj"});
}

test "validation order and messages" {
    c = open_client();
    try {
        seed(c);
        assert score(c, "Nobody", "Ghosts", "SPEED", 0)["reason"] == "unknown judge";
        assert score(c, "Ines", "Ghosts", "SPEED", 0)["reason"] == "unknown team";
        assert score(c, "Ines", "Otters", "SPEED", 0)["reason"] == "bad criterion";
        assert score(c, "Ines", "Otters", "craft", 5)["reason"] == "bad criterion";
        assert score(c, "Ines", "Otters", "CRAFT", 0)["reason"] == "bad points";
        assert score(c, "Ines", "Otters", "CRAFT", 11)["reason"] == "bad points";
        assert score(c, "Ines", "Otters", "CRAFT", 10)["ok"] == True;
        assert score(c, "Ines", "Otters", "DEMO", 1)["ok"] == True;
    } finally {
        c.close();
    }
}

test "leaderboard averages per judge and sorts" {
    c = open_client();
    try {
        seed(c);
        score(c, "Ines", "Otters", "IMPACT", 8);
        score(c, "Ines", "Otters", "CRAFT", 7);
        score(c, "Raj", "Otters", "IMPACT", 6);
        score(c, "Raj", "Badgers", "DEMO", 9);
        score(c, "Raj", "Badgers", "CRAFT", 1);
        board = walk(c, "leaderboard", {"track": ""});
        assert [r["team"] for r in board] == ["Otters", "Badgers", "Cranes"];
        assert board[0]["score"] == 10.5;
        assert board[0]["judges"] == 2;
        assert board[1]["score"] == 10.0;
        assert board[2]["score"] == 0.0;
        assert board[2]["judges"] == 0;
    } finally {
        c.close();
    }
}

test "rescoring replaces the previous points" {
    c = open_client();
    try {
        seed(c);
        score(c, "Ines", "Cranes", "DEMO", 3);
        score(c, "Ines", "Cranes", "DEMO", 9);
        board = walk(c, "leaderboard", {"track": "climate"});
        assert [r["team"] for r in board] == ["Cranes", "Otters"];
        assert board[0]["score"] == 9.0;
    } finally {
        c.close();
    }
}

test "ties by name and rounding" {
    c = open_client();
    try {
        seed(c);
        fn(c, "add_judge", {"name": "Zoe"});
        score(c, "Ines", "Cranes", "IMPACT", 5);
        score(c, "Ines", "Otters", "IMPACT", 5);
        score(c, "Ines", "Badgers", "IMPACT", 4);
        score(c, "Raj", "Badgers", "IMPACT", 3);
        score(c, "Zoe", "Badgers", "IMPACT", 3);
        board = walk(c, "leaderboard", {"track": ""});
        assert [r["team"] for r in board] == ["Cranes", "Otters", "Badgers"];
        assert board[2]["score"] == 3.33;
    } finally {
        c.close();
    }
}

test "judge progress lists teams not fully scored" {
    c = open_client();
    try {
        seed(c);
        for crit in ["IMPACT", "CRAFT", "DEMO"] {
            score(c, "Raj", "Cranes", crit, 5);
        }
        score(c, "Raj", "Otters", "IMPACT", 5);
        score(c, "Raj", "Otters", "IMPACT", 6);
        score(c, "Raj", "Otters", "CRAFT", 6);
        assert walk(c, "judge_progress", {"judge": "Raj"}) == ["Badgers", "Otters"];
        assert walk(c, "judge_progress", {"judge": "Ines"}) == ["Badgers", "Cranes", "Otters"];
        assert len(walk(c, "judge_progress", {"judge": "Nobody"})) == 0;
    } finally {
        c.close();
    }
}
