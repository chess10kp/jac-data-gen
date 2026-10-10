import uuid;
import from main { AddBook, Checkout, ReturnBook, Available, Overdue }

def get(x: any, k: str) -> any {
    return x[k] if isinstance(x, dict) else getattr(x, k);
}

def avail(isbn: str) -> int {
    return (root spawn Available(isbn=isbn)).reports[0];
}

test "checkout sets a 14 day due date and uses up copies" {
    isbn = "978-" + uuid.uuid4().hex[:8];
    root spawn AddBook(isbn=isbn, title="Dune", copies=2);
    assert avail(isbn) == 2;
    r = (root spawn Checkout(member="ann", isbn=isbn, date="2026-02-01")).reports[0];
    assert get(r, "ok") == True;
    assert get(r, "due") == "2026-02-15";
    assert avail(isbn) == 1;
    r2 = (root spawn Checkout(member="bob", isbn=isbn, date="2026-02-03")).reports[0];
    assert get(r2, "ok") == True;
    assert avail(isbn) == 0;
    r3 = (root spawn Checkout(member="cy", isbn=isbn, date="2026-02-03")).reports[0];
    assert get(r3, "ok") == False;
}

test "no double borrowing and unknown books" {
    isbn = "978-" + uuid.uuid4().hex[:8];
    root spawn AddBook(isbn=isbn, title="Emma", copies=3);
    who = "dee_" + uuid.uuid4().hex[:6];
    assert get((root spawn Checkout(member=who, isbn=isbn, date="2026-01-01")).reports[0], "ok") == True;
    assert get((root spawn Checkout(member=who, isbn=isbn, date="2026-01-02")).reports[0], "ok") == False;
    assert avail(isbn) == 2;
    assert get((root spawn Checkout(member=who, isbn="nope-" + isbn, date="2026-01-02")).reports[0], "ok") == False;
}

test "return frees a copy" {
    isbn = "978-" + uuid.uuid4().hex[:8];
    who = "eve_" + uuid.uuid4().hex[:6];
    root spawn AddBook(isbn=isbn, title="Ulysses", copies=1);
    root spawn Checkout(member=who, isbn=isbn, date="2026-04-01");
    assert avail(isbn) == 0;
    assert get((root spawn ReturnBook(member=who, isbn=isbn)).reports[0], "ok") == True;
    assert avail(isbn) == 1;
    assert get((root spawn ReturnBook(member=who, isbn=isbn)).reports[0], "ok") == False;
}

test "overdue lists only late loans in order" {
    isbn = "978-" + uuid.uuid4().hex[:8];
    a = "a_" + uuid.uuid4().hex[:6];
    b = "b_" + uuid.uuid4().hex[:6];
    c = "c_" + uuid.uuid4().hex[:6];
    root spawn AddBook(isbn=isbn, title="Beloved", copies=5);
    root spawn Checkout(member=b, isbn=isbn, date="2025-01-01");
    root spawn Checkout(member=a, isbn=isbn, date="2025-01-01");
    root spawn Checkout(member=c, isbn=isbn, date="2025-01-10");
    r = root spawn Overdue(date="2025-01-20");
    assert len(r.reports) == 1;
    mine = [x for x in r.reports[0] if get(x, "isbn") == isbn];
    assert list([get(x, "member") for x in mine]) == [a, b];
    assert get(mine[0], "due") == "2025-01-15";
    r2 = root spawn Overdue(date="2025-02-01");
    mine2 = [get(x, "member") for x in r2.reports[0] if get(x, "isbn") == isbn];
    assert list(mine2) == [a, b, c];
}
