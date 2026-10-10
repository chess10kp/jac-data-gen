import uuid;
import from main { submit_score }

def get(x: any, k: str) -> any {
    return x[k] if isinstance(x, dict) else getattr(x, k);
}

def flat(rs: list[any]) -> list[any] {
    if len(rs) == 1 and isinstance(rs[0], list) {
        return rs[0];
    }
    return rs;
}

def sub(g: str, p: str, s: int) -> list[any] {
    return flat((root spawn submit_score(game=g, player=p, score=s)).reports);
}

def rows(b: list[any]) -> list[tuple[str, int]] {
    return [(get(e, "player"), get(e, "score")) for e in b];
}

test "top five best first with initials" {
    g = "pac-" + uuid.uuid4().hex[:8];
    sub(g, "alice", 300);
    sub(g, "bob", 500);
    sub(g, "cat", 100);
    sub(g, "dan", 400);
    sub(g, "eve", 200);
    b = sub(g, "fay", 250);
    assert list(rows(b)) == [("BOB", 500), ("DAN", 400), ("ALI", 300), ("FAY", 250), ("EVE", 200)];
}

test "best per player only" {
    g = "pac-" + uuid.uuid4().hex[:8];
    sub(g, "amy", 100);
    b = sub(g, "AMY", 50);
    assert list(rows(b)) == [("AMY", 100)];
    b2 = sub(g, "amy", 150);
    assert list(rows(b2)) == [("AMY", 150)];
}

test "ties by first achieved and games separate" {
    g = "pac-" + uuid.uuid4().hex[:8];
    h = "dig-" + uuid.uuid4().hex[:8];
    sub(g, "xxx", 70);
    sub(g, "yyy", 70);
    b = sub(g, "zzz", 70);
    assert list(rows(b)) == [("XXX", 70), ("YYY", 70), ("ZZZ", 70)];
    assert list(rows(sub(h, "qqq", 1))) == [("QQQ", 1)];
}

test "negative score is an error and changes nothing" {
    g = "pac-" + uuid.uuid4().hex[:8];
    sub(g, "kim", 5);
    r = (root spawn submit_score(game=g, player="lee", score=-5)).reports;
    assert len(r) >= 1;
    assert isinstance(r[0], dict) and "error" in r[0];
    assert list(rows(sub(g, "kim", 1))) == [("KIM", 5)];
}
