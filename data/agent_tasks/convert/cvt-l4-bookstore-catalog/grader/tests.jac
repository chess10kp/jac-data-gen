import uuid;
import from catalog { Author, Book, Wrote, save_book, get_book, books_by_author, list_authors }

def run(w: Walker) -> any {
    return (root spawn w).reports[0];
}

test "first save creates author and book linked by Wrote" {
    t = uuid.uuid4().hex[:8];
    r = dict(run(save_book(url="https://ksd/" + t, book_title="Kobzar", author_name="Shevchenko " + t,
                           genre="poetry", publish_year=1840, price=12.5, count_in_complect=1)));
    assert r["saved"] == True and r["created"] == True;
    authors = [a for a in [root -->[?:Author]] if a.name == "Shevchenko " + t];
    assert len(authors) == 1 and jid(authors[0]) == r["author_id"];
    books = [b for b in [authors[0] ->:Wrote:->]];
    assert len(books) == 1 and books[0].title == "Kobzar" and jid(books[0]) == r["book_id"];
    v = dict(run(get_book(url="https://ksd/" + t)));
    assert v["author"] == "Shevchenko " + t and v["genre"] == "poetry" and v["publish_year"] == 1840;
    assert abs(v["price"] - 12.5) < 1e-9;
}

test "existing author is reused" {
    t = uuid.uuid4().hex[:8];
    a1 = dict(run(save_book(url="u1" + t, book_title="One", author_name="Franko " + t)));
    a2 = dict(run(save_book(url="u2" + t, book_title="Two", author_name="Franko " + t)));
    assert a1["author_id"] == a2["author_id"] and a1["book_id"] != a2["book_id"];
    assert list(run(list_authors())).count("Franko " + t) == 1;
    assert sorted(list(run(books_by_author(author_name="Franko " + t)))) == ["One", "Two"];
}

test "same url refreshes the book instead of duplicating" {
    t = uuid.uuid4().hex[:8];
    first = dict(run(save_book(url="dup" + t, book_title="Old title", author_name="Ukrainka " + t, price=10.0, isbn="111")));
    second = dict(run(save_book(url="dup" + t, book_title="New title", author_name="Ukrainka " + t, price=8.0)));
    assert second["saved"] == True and second["created"] == False;
    assert second["book_id"] == first["book_id"];
    assert list(run(books_by_author(author_name="Ukrainka " + t))) == ["New title"];
    v = dict(run(get_book(url="dup" + t)));
    assert v["title"] == "New title" and abs(v["price"] - 8.0) < 1e-9;
    assert v["isbn"] is None;
}

test "refresh with a different author moves the book" {
    t = uuid.uuid4().hex[:8];
    dict(run(save_book(url="mv" + t, book_title="Moved", author_name="A " + t)));
    r = dict(run(save_book(url="mv" + t, book_title="Moved", author_name="B " + t)));
    assert r["created"] == False;
    assert len(list(run(books_by_author(author_name="A " + t)))) == 0;
    assert list(run(books_by_author(author_name="B " + t))) == ["Moved"];
    assert dict(run(get_book(url="mv" + t)))["author"] == "B " + t;
}

test "complect volumes and author-less records are skipped" {
    t = uuid.uuid4().hex[:8];
    r = dict(run(save_book(url="set" + t, book_title="Box set", author_name="C " + t, count_in_complect=3)));
    assert r["saved"] == False;
    assert run(get_book(url="set" + t)) is None;
    assert "C " + t not in list(run(list_authors()));
    r2 = dict(run(save_book(url="anon" + t, book_title="Anon")));
    assert r2["saved"] == False;
    assert run(get_book(url="anon" + t)) is None;
}

test "unknown lookups are empty" {
    assert run(get_book(url="missing-" + uuid.uuid4().hex)) is None;
    assert len(list(run(books_by_author(author_name="Nobody " + uuid.uuid4().hex)))) == 0;
}
