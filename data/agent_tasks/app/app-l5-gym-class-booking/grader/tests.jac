import uuid;
import from main { create_class, book_spot, cancel_booking, list_classes, roster }

def get(x: any, k: str) -> any {
    return x[k] if isinstance(x, dict) else getattr(x, k);
}

def is_err(x: any) -> bool {
    return isinstance(x, dict) and "error" in x;
}

test "create and view shape" {
    n = "Yoga " + uuid.uuid4().hex[:6];
    c = create_class(name=n, capacity=2);
    assert not is_err(c);
    assert get(c, "name") == n and get(c, "capacity") == 2;
    assert get(c, "booked") == 0 and get(c, "spots_left") == 2;
    assert isinstance(get(c, "id"), str) and len(get(c, "id")) > 0;
    assert is_err(create_class(name=n + "x", capacity=0));
}

test "booking rules" {
    c = create_class(name="Boulder " + uuid.uuid4().hex[:6], capacity=2);
    cid = get(c, "id");
    v = book_spot(class_id=cid, member="ana");
    assert get(v, "booked") == 1 and get(v, "spots_left") == 1;
    assert is_err(book_spot(class_id=cid, member="ana"));
    v = book_spot(class_id=cid, member="Ana");
    assert get(v, "booked") == 2 and get(v, "spots_left") == 0;
    assert is_err(book_spot(class_id=cid, member="cy"));
    assert is_err(book_spot(class_id="no-such-" + cid, member="cy"));
    assert list(roster(class_id=cid)) == ["Ana", "ana"];
}

test "cancel frees a spot" {
    c = create_class(name="Ropes " + uuid.uuid4().hex[:6], capacity=1);
    cid = get(c, "id");
    book_spot(class_id=cid, member="dee");
    assert is_err(cancel_booking(class_id=cid, member="eve"));
    v = cancel_booking(class_id=cid, member="dee");
    assert get(v, "booked") == 0 and get(v, "spots_left") == 1;
    assert len(roster(class_id=cid)) == 0;
    assert get(book_spot(class_id=cid, member="eve"), "booked") == 1;
}

test "list classes sorted by name" {
    tag = uuid.uuid4().hex[:6];
    create_class(name="zz-" + tag, capacity=1);
    create_class(name="aa-" + tag, capacity=1);
    names = [get(v, "name") for v in list_classes()];
    mine = [n for n in names if n.endswith(tag)];
    assert list(mine) == ["aa-" + tag, "zz-" + tag];
    assert names == sorted(names);
}
