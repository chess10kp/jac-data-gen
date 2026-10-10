import uuid;
import from main { record_visit }

def get(x: any, k: str) -> any {
    return x[k] if isinstance(x, dict) else getattr(x, k);
}

test "counts per page" {
    a = "/a-" + uuid.uuid4().hex[:8];
    b = "/b-" + uuid.uuid4().hex[:8];
    r1 = (root spawn record_visit(page=a)).reports[0];
    assert get(r1, "page") == a and get(r1, "visits") == 1;
    assert get((root spawn record_visit(page=a)).reports[0], "visits") == 2;
    assert get((root spawn record_visit(page=b)).reports[0], "visits") == 1;
    assert get((root spawn record_visit(page=a)).reports[0], "visits") == 3;
}

test "trimmed and case sensitive" {
    a = "/Case-" + uuid.uuid4().hex[:8];
    root spawn record_visit(page=a);
    assert get((root spawn record_visit(page="  " + a + " ")).reports[0], "visits") == 2;
    assert get((root spawn record_visit(page=a.lower())).reports[0], "visits") == 1;
}

test "blank page reports an error" {
    r = (root spawn record_visit(page="  ")).reports[0];
    assert "error" in r;
}
