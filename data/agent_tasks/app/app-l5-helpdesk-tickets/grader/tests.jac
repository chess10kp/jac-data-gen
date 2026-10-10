import uuid;
import from main { open_ticket, assign_ticket, add_comment, close_ticket, list_tickets }

def get(x: any, k: str) -> any {
    return x[k] if isinstance(x, dict) else getattr(x, k);
}

def is_err(x: any) -> bool {
    return isinstance(x, dict) and "error" in x;
}

def first(rs: list[any]) -> any {
    assert len(rs) >= 1;
    return rs[0];
}

def flat(rs: list[any]) -> list[any] {
    if len(rs) == 1 and isinstance(rs[0], list) {
        return rs[0];
    }
    return rs;
}

test "numbers are sequential and view shape" {
    s = "vpn " + uuid.uuid4().hex[:6];
    a = first((root spawn open_ticket(subject=s, priority="high")).reports);
    b = first((root spawn open_ticket(subject=s + "b")).reports);
    assert get(b, "number") == get(a, "number") + 1;
    assert get(a, "subject") == s and get(a, "priority") == "high";
    assert get(a, "status") == "open" and get(a, "agent") == "";
    assert len(get(a, "comments")) == 0;
    assert get(b, "priority") == "normal";
}

test "assign comment close" {
    t = first((root spawn open_ticket(subject="mail " + uuid.uuid4().hex[:6], priority="normal")).reports);
    n = get(t, "number");
    assert is_err(first((root spawn close_ticket(number=n)).reports));
    a = first((root spawn assign_ticket(number=n, agent="kim")).reports);
    assert get(a, "agent") == "kim";
    root spawn add_comment(number=n, author="kim", body="looking");
    c = first((root spawn add_comment(number=n, author="lee", body="fixed")).reports);
    cs = get(c, "comments");
    assert list([get(x, "body") for x in cs]) == ["looking", "fixed"];
    assert get(cs[1], "author") == "lee";
    d = first((root spawn close_ticket(number=n)).reports);
    assert get(d, "status") == "closed";
    assert is_err(first((root spawn close_ticket(number=n)).reports));
    assert is_err(first((root spawn add_comment(number=n, author="x", body="late")).reports));
}

test "bad requests are errors" {
    assert is_err(first((root spawn open_ticket(subject="   ", priority="low")).reports));
    assert is_err(first((root spawn open_ticket(subject="x", priority="urgent")).reports));
    assert is_err(first((root spawn assign_ticket(number=10 ** 7, agent="kim")).reports));
    assert is_err(first((root spawn add_comment(number=10 ** 7, author="a", body="b")).reports));
}

test "list ordering and status filter" {
    tag = uuid.uuid4().hex[:6];
    lo = get(first((root spawn open_ticket(subject="lo " + tag, priority="low")).reports), "number");
    hi = get(first((root spawn open_ticket(subject="hi " + tag, priority="high")).reports), "number");
    no = get(first((root spawn open_ticket(subject="no " + tag, priority="normal")).reports), "number");
    hi2 = get(first((root spawn open_ticket(subject="hi2 " + tag, priority="high")).reports), "number");
    all_t = flat((root spawn list_tickets()).reports);
    mine = [get(t, "number") for t in all_t if get(t, "subject").endswith(tag)];
    assert list(mine) == [hi, hi2, no, lo];
    root spawn assign_ticket(number=no, agent="kim");
    root spawn close_ticket(number=no);
    closed = [get(t, "number") for t in flat((root spawn list_tickets(status="closed")).reports)];
    opened = [get(t, "number") for t in flat((root spawn list_tickets(status="open")).reports)];
    assert no in closed and no not in opened;
    assert hi in opened and hi not in closed;
}
