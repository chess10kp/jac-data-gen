import uuid;
import from main { SaveBookmark, FindByTag, TagCounts, DeleteBookmark }

def one(rs: list[any]) -> any {
    return rs[0];
}

test "save and find by tag" {
    t = "tg" + uuid.uuid4().hex[:6];
    u1 = f"https://a.example/{t}";
    u2 = f"https://b.example/{t}";
    root spawn SaveBookmark(url=u2, title="B", tags=[t, "Misc " + t]);
    root spawn SaveBookmark(url=u1, title="A", tags=[" " + t.upper() + " ", ""]);
    r = root spawn FindByTag(tag=t);
    assert len(r.reports) == 1;
    assert list(one(r.reports)) == [u1, u2];
    assert list(one((root spawn FindByTag(tag=("misc " + t).upper())).reports)) == [u2];
    assert len(one((root spawn FindByTag(tag="none" + t)).reports)) == 0;
}

test "resave merges tags without duplicating bookmark" {
    t = "tg" + uuid.uuid4().hex[:6];
    u = f"https://c.example/{t}";
    root spawn SaveBookmark(url=u, title="old", tags=[t + "x"]);
    root spawn SaveBookmark(url=u, title="new", tags=[t + "y", t + "x"]);
    assert list(one((root spawn FindByTag(tag=t + "x")).reports)) == [u];
    assert list(one((root spawn FindByTag(tag=t + "y")).reports)) == [u];
    counts = one((root spawn TagCounts()).reports);
    assert counts[t + "x"] == 1 and counts[t + "y"] == 1;
}

test "tags are shared nodes counted per bookmark" {
    t = "tg" + uuid.uuid4().hex[:6];
    for i in range(3) {
        root spawn SaveBookmark(url=f"https://d.example/{t}/{i}", title="d", tags=[t]);
    }
    counts = one((root spawn TagCounts()).reports);
    assert counts[t] == 3;
}

test "delete removes bookmark and orphaned tags" {
    t = "tg" + uuid.uuid4().hex[:6];
    u = f"https://e.example/{t}";
    keep = f"https://f.example/{t}";
    root spawn SaveBookmark(url=u, title="e", tags=[t + "solo", t + "shared"]);
    root spawn SaveBookmark(url=keep, title="f", tags=[t + "shared"]);
    assert one((root spawn DeleteBookmark(url=u)).reports) == True;
    assert one((root spawn DeleteBookmark(url=u)).reports) == False;
    assert len(one((root spawn FindByTag(tag=t + "solo")).reports)) == 0;
    assert list(one((root spawn FindByTag(tag=t + "shared")).reports)) == [keep];
    counts = one((root spawn TagCounts()).reports);
    assert (t + "solo") not in list(counts);
    assert counts[t + "shared"] == 1;
}
