import from main { Bookmark, Tag, Tagged, clean_tags, SaveBookmark, FindByTag, TagCounts, DeleteBookmark }

def save(url: str, title: str, tags: list[str]) -> Bookmark {
    w = root spawn SaveBookmark(url=url, title=title, tags=tags);
    assert len(w.reports) == 1;
    return w.reports[0];
}

def by_tag(t: str) -> list[str] {
    return list((root spawn FindByTag(tag=t)).reports[0]);
}

def tag_names(b: Bookmark) -> list[str] {
    return sorted([t.name for t in [b ->:Tagged:->]]);
}

test "save returns the bookmark" {
    b = (root spawn SaveBookmark(url="https://a.example", title="A", tags=["x"])).reports[0];
    assert b.url == "https://a.example";
    assert b.title == "A";
}

test "clean_tags trims, lowercases, drops blanks and duplicates in order" {
    assert list(clean_tags([" Jac ", "jac", "", "  ", "Graph", "GRAPH", "zeta"])) == ["jac", "graph", "zeta"];
    assert len(clean_tags([])) == 0;
}

test "tags are shared nodes" {
    save("u1", "one", ["news", "tech"]);
    save("u2", "two", ["Tech"]);
    assert len([root -->[?:Tag]]) == 2;
    assert len([root -->[?:Bookmark]]) == 2;
}

test "re-saving updates the title and merges tags" {
    b = save("u1", "first", ["a", "b"]);
    b2 = save("u1", "second", ["B", "c"]);
    assert b2 == b;
    assert b.title == "second";
    assert tag_names(b) == ["a", "b", "c"];
    assert len([root -->[?:Bookmark]]) == 1;
}

test "saving without tags" {
    b = save("u1", "t", []);
    assert len(tag_names(b)) == 0;
    assert len([root -->[?:Tag]]) == 0;
}

test "find by tag is normalised and sorted" {
    save("https://z", "z", ["read"]);
    save("https://a", "a", ["read", "later"]);
    save("https://m", "m", ["later"]);
    assert by_tag("  READ ") == ["https://a", "https://z"];
    assert by_tag("later") == ["https://a", "https://m"];
    assert len(by_tag("nope")) == 0;
}

test "tag counts" {
    save("u1", "", ["a", "b"]);
    save("u2", "", ["a"]);
    save("u3", "", ["a", "c"]);
    w = root spawn TagCounts();
    assert len(w.reports) == 1;
    assert dict(w.reports[0]) == {"a": 3, "b": 1, "c": 1};
}

test "delete removes bookmark and orphaned tags only" {
    save("u1", "", ["shared", "solo"]);
    save("u2", "", ["shared"]);
    assert (root spawn DeleteBookmark(url="u1")).reports[0] == True;
    assert len([root -->[?:Bookmark]]) == 1;
    assert sorted([t.name for t in [root -->[?:Tag]]]) == ["shared"];
    assert by_tag("shared") == ["u2"];
    assert dict((root spawn TagCounts()).reports[0]) == {"shared": 1};
}

test "delete of unknown url" {
    save("u1", "", ["x"]);
    assert (root spawn DeleteBookmark(url="nope")).reports[0] == False;
    assert len([root -->[?:Bookmark]]) == 1;
    assert len([root -->[?:Tag]]) == 1;
}
