import uuid;
import from main { adjust_stock }

def get(x: any, k: str) -> any {
    return x[k] if isinstance(x, dict) else getattr(x, k);
}

def adj(s: str, d: int, why: str = "") -> any {
    return (root spawn adjust_stock(sku=s, delta=d, reason=why)).reports[0];
}

test "create, receive and consume" {
    s = "brk-" + uuid.uuid4().hex[:6];
    r = adj(s, 10, "delivery");
    assert get(r, "sku") == s.upper() and get(r, "quantity") == 10 and get(r, "movements") == 1;
    r = adj(s.upper(), -3, "repair");
    assert get(r, "quantity") == 7 and get(r, "movements") == 2;
}

test "insufficient stock leaves state alone" {
    s = "cbl-" + uuid.uuid4().hex[:6];
    adj(s, 2);
    bad = adj(s, -5);
    assert get(bad, "error") == "insufficient stock";
    assert get(bad, "quantity") == 2;
    ok = adj(s, -2);
    assert get(ok, "quantity") == 0 and get(ok, "movements") == 2;
}

test "unknown sku with non-positive delta is an error" {
    s = "ghost-" + uuid.uuid4().hex[:6];
    r = adj(s, -1);
    assert isinstance(r, dict) and "error" in list(r);
    r2 = adj(s, 0);
    assert isinstance(r2, dict) and "error" in list(r2);
    r3 = adj(s, 4);
    assert get(r3, "quantity") == 4 and get(r3, "movements") == 1;
}
