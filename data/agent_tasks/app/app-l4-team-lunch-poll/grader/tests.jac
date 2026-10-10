import uuid;
import from main { cast_vote }

def get(x: any, k: str) -> any {
    return x[k] if isinstance(x, dict) else getattr(x, k);
}

def vote(poll: str, voter: str, choice: str) -> any {
    r = root spawn cast_vote(poll=poll, voter=voter, choice=choice);
    assert len(r.reports) >= 1;
    return r.reports[-1];
}

test "tallies and leader" {
    p = "fri-" + uuid.uuid4().hex[:8];
    vote(p, "ann", "Tacos");
    vote(p, "bob", "pho");
    s = vote(p, "cy", "tacos");
    assert get(s, "poll") == p;
    assert get(s, "tallies") == {"tacos": 2, "pho": 1};
    assert get(s, "leader") == "tacos";
}

test "revote moves vote and empty choices vanish" {
    p = "fri-" + uuid.uuid4().hex[:8];
    vote(p, "ann", "curry");
    vote(p, "bob", "salad");
    s = vote(p, "ann", "SALAD");
    assert get(s, "tallies") == {"salad": 2};
    assert get(s, "leader") == "salad";
}

test "tie goes alphabetical and polls are independent" {
    p = "fri-" + uuid.uuid4().hex[:8];
    q = "fri-" + uuid.uuid4().hex[:8];
    vote(p, "ann", "ramen");
    s = vote(p, "bob", "burgers");
    assert get(s, "leader") == "burgers";
    t = vote(q, "ann", "ramen");
    assert get(t, "tallies") == {"ramen": 1};
}
