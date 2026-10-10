# Hidden tests for the book catalog port (in-process walker spawns). The graph store
# persists between tests, so data is tagged with a uuid and assertions are deltas.
import uuid;
import from main { Book, health, create_book, list_books, get_book, update_book, delete_book, genre_stats }

def first(rs: list[any]) -> dict[str, any] {
    assert len(rs) > 0;
    return dict(rs[0]);
}

def add(title: str, author: str, genres: list[str]) -> dict[str, any] {
    return first((root spawn create_book(title=title, author=author, genres=genres, pages=100)).reports);
}

def by_author(author: str) -> dict[str, any] {
    return first((root spawn list_books(author=author)).reports);
}

def stats -> list[dict[str, any]] {
    rs = (root spawn genre_stats()).reports;
    rows = rs[0] if len(rs) == 1 and isinstance(rs[0], list) else rs;
    return [dict(r) for r in rows];
}

test "health" {
    r = first((root spawn health()).reports);
    assert r["status"] == "healthy" and r["db"] == "connected";
}

test "create returns the stored book with defaults" {
    tag = uuid.uuid4().hex[:8];
    b = add("Dune " + tag, "Herbert " + tag, ["scifi"]);
    assert len(b["id"]) > 0 and b["title"] == "Dune " + tag;
    assert b["in_stock"] == True and b["rating"] is None and b["pages"] == 100;
    assert list(b["genres"]) == ["scifi"];
    assert len(b["created_at"]) > 0 and b["created_at"] == b["updated_at"];
    assert len([n for n in [root -->[?:Book]] if n.title == "Dune " + tag]) == 1;
}

test "list filters by author, newest first" {
    tag = uuid.uuid4().hex[:8];
    a = "Le Guin " + tag;
    x = add("One " + tag, a, []);
    y = add("Two " + tag, a, []);
    add("Other " + tag, "Somebody " + tag, []);
    r = by_author(a);
    assert r["count"] == 2;
    assert [dict(b)["title"] for b in r["books"]] == ["Two " + tag, "One " + tag];
    every = first((root spawn list_books()).reports);
    ids = [dict(b)["id"] for b in every["books"]];
    assert every["count"] == len(ids);
    assert x["id"] in ids and y["id"] in ids;
}

test "get by id and missing id" {
    tag = uuid.uuid4().hex[:8];
    b = add("Emma " + tag, "Austen " + tag, ["classic"]);
    got = first((root spawn get_book(book_id=b["id"])).reports);
    assert got["title"] == "Emma " + tag and got["author"] == "Austen " + tag;
    miss = first((root spawn get_book(book_id="000000000000000000000000")).reports);
    assert miss["error"] == "not found";
}

test "partial update keeps other fields and bumps updated_at" {
    tag = uuid.uuid4().hex[:8];
    b = add("Draft " + tag, "Writer " + tag, ["essay"]);
    u = first((root spawn update_book(book_id=b["id"], rating=4.5, in_stock=False)).reports);
    assert u["rating"] == 4.5 and u["in_stock"] == False;
    assert u["title"] == "Draft " + tag and list(u["genres"]) == ["essay"] and u["pages"] == 100;
    assert u["updated_at"] >= u["created_at"] and u["created_at"] == b["created_at"];
    again = first((root spawn get_book(book_id=b["id"])).reports);
    assert again["rating"] == 4.5 and again["in_stock"] == False;
    miss = first((root spawn update_book(book_id="000000000000000000000000", title="x")).reports);
    assert miss["error"] == "not found";
}

test "delete removes exactly one book" {
    tag = uuid.uuid4().hex[:8];
    a = "Deleter " + tag;
    x = add("Keep " + tag, a, []);
    y = add("Drop " + tag, a, []);
    r = first((root spawn delete_book(book_id=y["id"])).reports);
    assert "error" not in r;
    left = by_author(a);
    assert left["count"] == 1 and dict(left["books"][0])["id"] == x["id"];
    again = first((root spawn delete_book(book_id=y["id"])).reports);
    assert again["error"] == "not found";
}

test "genre stats count books per genre, most common first" {
    tag = uuid.uuid4().hex[:8];
    g1 = "fantasy-" + tag;
    g2 = "horror-" + tag;
    add("A" + tag, "X" + tag, [g1, g2]);
    add("B" + tag, "X" + tag, [g1]);
    add("C" + tag, "X" + tag, [g1]);
    rows = stats();
    mine = {r["_id"]: r["count"] for r in rows if str(r["_id"]).endswith(tag)};
    assert mine[g1] == 3 and mine[g2] == 1;
    counts = [r["count"] for r in rows];
    assert counts == sorted(counts, reverse=True);
}
