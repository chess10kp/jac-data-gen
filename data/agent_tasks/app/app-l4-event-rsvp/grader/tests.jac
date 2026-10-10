import uuid;
import from main { rsvp }

def get(x: any, k: str) -> any {
    return x[k] if isinstance(x, dict) else getattr(x, k);
}

def say(ev: str, who: str, yes: bool, plus: int = 0) -> any {
    return (root spawn rsvp(event=ev, guest=who, attending=yes, plus_ones=plus)).reports[0];
}

test "headcount and sorted lists" {
    ev = "cleanup-" + uuid.uuid4().hex[:8];
    say(ev, "sam", True);
    say(ev, "Dana Lee", True, 1);
    s = say(ev, "Alex", False);
    assert get(s, "event") == ev;
    assert get(s, "headcount") == 3;
    assert list(get(s, "attending")) == ["Dana Lee", "sam"];
    assert list(get(s, "declined")) == ["Alex"];
}

test "latest rsvp wins and keeps latest spelling" {
    ev = "cleanup-" + uuid.uuid4().hex[:8];
    say(ev, "dana lee", True, 3);
    s = say(ev, "  DANA LEE ", False);
    assert get(s, "headcount") == 0;
    assert len(get(s, "attending")) == 0;
    assert list(get(s, "declined")) == ["DANA LEE"];
    s2 = say(ev, "Dana Lee", True, 2);
    assert get(s2, "headcount") == 3;
    assert list(get(s2, "attending")) == ["Dana Lee"];
    assert len(get(s2, "declined")) == 0;
}

test "plus ones validated" {
    ev = "cleanup-" + uuid.uuid4().hex[:8];
    say(ev, "Ann", True);
    bad = say(ev, "Bo", True, 4);
    assert isinstance(bad, dict) and "error" in list(bad);
    bad2 = say(ev, "Bo", True, -1);
    assert isinstance(bad2, dict) and "error" in list(bad2);
    s = say(ev, "Cy", False);
    assert get(s, "headcount") == 1;
    assert "Bo" not in list(get(s, "attending")) and "Bo" not in list(get(s, "declined"));
}

test "events are separate" {
    a = "cleanup-" + uuid.uuid4().hex[:8];
    b = "cleanup-" + uuid.uuid4().hex[:8];
    say(a, "Pat", True, 1);
    s = say(b, "Pat", False);
    assert get(s, "headcount") == 0;
    assert get(say(a, "Quinn", True), "headcount") == 3;
}
