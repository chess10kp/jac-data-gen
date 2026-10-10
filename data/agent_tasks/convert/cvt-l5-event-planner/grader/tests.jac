# Hidden tests: upstream tests/test_events.py + tests/test_users.py, ported to in-process
# walker spawns. The graph store persists, so every test tags its data with a uuid and
# asserts on deltas, never on absolute counts.
import uuid;
import from main { User, Event, sign_new_user, get_all_events, get_event_by_id, create_event, update_event, delete_event, delete_all_events }

def first(rs: list[any]) -> dict[str, any] {
    assert len(rs) > 0;
    return dict(rs[0]);
}

def all_events -> list[dict[str, any]] {
    rs = (root spawn get_all_events()).reports;
    if len(rs) == 1 and isinstance(rs[0], list) {
        return [dict(x) for x in rs[0]];
    }
    return [dict(x) for x in rs];
}

def new_event(user: str, title: str) -> str {
    r = first((root spawn create_event(user=user, title=title, image="https://example.com/i.jpg",
                           description="desc " + title, tags=["test", "event"], location="Hall")).reports);
    assert r["message"] == "Event created successfully";
    return r["id"];
}

test "signup stores a hashed password and rejects duplicates" {
    email = f"u{uuid.uuid4().hex[:8]}@example.com";
    r = first((root spawn sign_new_user(email=email, password="testpassword")).reports);
    assert r["message"] == "User created successfully";
    mine = [u for u in [root -->[?:User]] if u.email == email];
    assert len(mine) == 1;
    assert mine[0].password != "testpassword" and len(mine[0].password) > 0;
    again = first((root spawn sign_new_user(email=email, password="other")).reports);
    assert again["error"] == "User with supplied email already exists";
    assert len([u for u in [root -->[?:User]] if u.email == email]) == 1;
}

test "create and fetch by id" {
    tag = uuid.uuid4().hex[:8];
    before = len(all_events());
    eid = new_event("a@x.com", "Party " + tag);
    evs = all_events();
    assert len(evs) == before + 1;
    got = first((root spawn get_event_by_id(event_id=eid)).reports);
    assert got["id"] == eid and got["title"] == "Party " + tag;
    assert got["creator"] == "a@x.com" and got["location"] == "Hall";
    assert list(got["tags"]) == ["test", "event"];
    assert len([e for e in evs if e["id"] == eid]) == 1;
}

test "unknown event id" {
    r = first((root spawn get_event_by_id(event_id="507f1f77bcf86cd799439011")).reports);
    assert r["error"] == "Event with supplied ID does not exist";
}

test "partial update by the creator" {
    tag = uuid.uuid4().hex[:8];
    eid = new_event("owner@x.com", "Meetup " + tag);
    r = first((root spawn update_event(event_id=eid, user="owner@x.com", title="Updated " + tag)).reports);
    assert r["title"] == "Updated " + tag;
    got = first((root spawn get_event_by_id(event_id=eid)).reports);
    assert got["title"] == "Updated " + tag;
    assert got["description"] == "desc Meetup " + tag and got["location"] == "Hall";
    r2 = first((root spawn update_event(event_id=eid, user="owner@x.com", tags=["x"], location="Roof")).reports);
    assert list(r2["tags"]) == ["x"] and r2["location"] == "Roof" and r2["title"] == "Updated " + tag;
}

test "update rules: unknown id and other users" {
    r = first((root spawn update_event(event_id="507f1f77bcf86cd799439011", user="a@x.com", title="t")).reports);
    assert r["error"] == "Event with supplied ID does not exist";
    eid = new_event("owner@x.com", "Locked " + uuid.uuid4().hex[:8]);
    r2 = first((root spawn update_event(event_id=eid, user="intruder@x.com", title="hacked")).reports);
    assert r2["error"] == "Operation not allowed";
    assert first((root spawn get_event_by_id(event_id=eid)).reports)["title"] != "hacked";
}

test "delete only own event" {
    a = new_event("owner@x.com", "A" + uuid.uuid4().hex[:8]);
    b = new_event("owner@x.com", "B" + uuid.uuid4().hex[:8]);
    denied = first((root spawn delete_event(event_id=a, user="intruder@x.com")).reports);
    assert denied["error"] == "Operation not allowed";
    ok = first((root spawn delete_event(event_id=a, user="owner@x.com")).reports);
    assert ok["message"] == "Event deleted successfully";
    ids = [e["id"] for e in all_events()];
    assert a not in ids and b in ids;
    gone = first((root spawn delete_event(event_id=a, user="owner@x.com")).reports);
    assert gone["error"] == "Event with supplied ID does not exist";
}

test "delete all events" {
    new_event("a@x.com", "X" + uuid.uuid4().hex[:8]);
    new_event("b@x.com", "Y" + uuid.uuid4().hex[:8]);
    r = first((root spawn delete_all_events(user="a@x.com")).reports);
    assert r["message"] == "All events deleted successfully";
    assert len(all_events()) == 0;
    assert len([e for e in [root -->[?:Event]]]) == 0;
}
