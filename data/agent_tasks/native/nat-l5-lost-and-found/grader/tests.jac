import tempfile;
import from jaclang.testing.testing { JacTestClient }

def open_client -> JacTestClient {
    c = JacTestClient.from_file("app.jac", base_path=tempfile.mkdtemp());
    c.register_user("desk", "password123");
    return c;
}

def walk(c: JacTestClient, name: str, body: dict[str, any]) -> any {
    resp = c.post("/walker/" + name, json=body);
    assert resp.status_code == 200, f"{name}: {resp.status_code} {resp.text}";
    return resp.json()["data"]["reports"][0];
}

def log(c: JacTestClient, cat: str, color: str, day: int) -> str {
    resp = c.post("/function/log_item", json={"category": cat, "color": color, "found_day": day, "location": "tram 4"});
    return resp.json()["data"]["result"];
}

test "search filters and orders newest first" {
    c = open_client();
    try {
        a = log(c, "BAG", "Red", 3);
        b = log(c, "BAG", "red", 7);
        log(c, "BAG", "blue", 8);
        log(c, "PHONE", "red", 9);
        d = log(c, "BAG", "RED", 7);
        log(c, "BAG", "red", 1);
        hits = walk(c, "search", {"category": "BAG", "color": "rEd", "since_day": 3});
        assert hits == [b, d, a];
        assert len(walk(c, "search", {"category": "SOCK", "color": "red", "since_day": 0})) == 0;
    } finally {
        c.close();
    }
}

test "claim flow" {
    c = open_client();
    try {
        t = log(c, "KEYS", "silver", 2);
        assert walk(c, "claim", {"tag": "LF-99", "name": "Ana"})["reason"] == "unknown item";
        assert walk(c, "claim", {"tag": t, "name": "Ana"})["ok"] == True;
        again = walk(c, "claim", {"tag": t, "name": "Bo"});
        assert again["ok"] == False;
        assert again["reason"] == "already claimed";
        assert len(walk(c, "search", {"category": "KEYS", "color": "silver", "since_day": 0})) == 0;
    } finally {
        c.close();
    }
}

test "expire donates only old unclaimed items" {
    c = open_client();
    try {
        old1 = log(c, "UMBRELLA", "black", 1);
        old2 = log(c, "OTHER", "green", 2);
        edge_day = log(c, "BAG", "tan", 10);
        kept = log(c, "PHONE", "white", 1);
        walk(c, "claim", {"tag": kept, "name": "Cy"});
        gone = walk(c, "expire", {"today": 40, "keep_days": 30});
        assert gone == [old1, old2];
        s = walk(c, "stats", {});
        assert s["UMBRELLA"]["open"] == 0;
        assert s["BAG"]["open"] == 1;
        assert s["PHONE"]["claimed"] == 1;
        assert len(walk(c, "expire", {"today": 40, "keep_days": 30})) == 0;
    } finally {
        c.close();
    }
}

test "stats cover every category" {
    c = open_client();
    try {
        log(c, "BAG", "red", 1);
        t = log(c, "BAG", "red", 1);
        walk(c, "claim", {"tag": t, "name": "Di"});
        s = walk(c, "stats", {});
        assert sorted(s.keys()) == ["BAG", "KEYS", "OTHER", "PHONE", "UMBRELLA"];
        assert s["BAG"] == {"open": 1, "claimed": 1};
        assert s["KEYS"] == {"open": 0, "claimed": 0};
    } finally {
        c.close();
    }
}
