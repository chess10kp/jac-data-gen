import uuid;
import from main { Entry, welcome, retrieve_entries, add_entry, delete_entry }

def entries -> list[dict[str, str]] {
    return (root spawn retrieve_entries()).reports[0]["entries"];
}

def add(name: str, text: str) -> str {
    msg: str = (root spawn add_entry(name=name, `entry=text)).reports[0]["message"];
    assert msg.startswith("New entry added with ID: ");
    return msg.split("ID: ")[1];
}

test "welcome message" {
    msg: str = (root spawn welcome()).reports[0]["message"];
    assert "Welcome to the FastAPI + Okteto" in msg;
}

test "add then list" {
    tag = uuid.uuid4().hex[:8];
    before = len(entries());
    eid = add("Ann " + tag, "hello " + tag);
    after = entries();
    assert len(after) == before + 1;
    mine = [e for e in after if e["id"] == eid];
    assert len(mine) == 1;
    assert mine[0]["name"] == "Ann " + tag and mine[0]["entry"] == "hello " + tag;
    assert len(mine[0]["date"]) > 0;
    assert len([n for n in [root -->[?:Entry]] if n.name == "Ann " + tag]) == 1;
}

test "delete removes only that entry" {
    tag = uuid.uuid4().hex[:8];
    a = add("A" + tag, "one");
    b = add("B" + tag, "two");
    msg = (root spawn delete_entry(id=a)).reports[0]["message"];
    assert "deleted successfully" in msg;
    ids = [e["id"] for e in entries()];
    assert a not in ids and b in ids;
}

test "delete unknown id still succeeds" {
    before = len(entries());
    msg = (root spawn delete_entry(id="507f1f77bcf86cd799439011")).reports[0]["message"];
    assert "deleted successfully" in msg;
    assert len(entries()) == before;
}
