import from main { Book, Member, Loan, find_book, available_copies, AddBook, Checkout, ReturnBook, Available, Overdue }

def add(isbn: str, title: str, copies: int) -> Book {
    return (root spawn AddBook(isbn=isbn, title=title, copies=copies)).reports[0];
}

def lend(who: str, isbn: str, date: str) -> dict {
    w = root spawn Checkout(member=who, isbn=isbn, date=date);
    assert len(w.reports) == 1;
    return w.reports[0];
}

def back(who: str, isbn: str) -> bool {
    return (root spawn ReturnBook(member=who, isbn=isbn)).reports[0]["ok"];
}

def avail(isbn: str) -> int {
    return (root spawn Available(isbn=isbn)).reports[0];
}

test "add book and re-add updates in place" {
    b = add("111", "Old Title", 1);
    assert b.title == "Old Title";
    b2 = add("111", "New Title", 4);
    assert b2 == b;
    assert b.title == "New Title";
    assert b.copies == 4;
    assert len([root -->[?:Book]]) == 1;
    assert avail("111") == 4;
}

test "unknown isbn has zero availability" {
    assert avail("000") == 0;
    assert find_book("000") is None;
}

test "due date is fourteen days later" {
    add("1", "A", 1);
    r = lend("ann", "1", "2026-03-01");
    assert r["ok"] == True;
    assert r["due"] == "2026-03-15";
}

test "due date rolls over month and year" {
    add("1", "A", 2);
    assert lend("ann", "1", "2026-01-25")["due"] == "2026-02-08";
    assert lend("bob", "1", "2026-12-25")["due"] == "2027-01-08";
}

test "copies run out" {
    add("1", "A", 2);
    assert lend("ann", "1", "2026-01-01")["ok"] == True;
    assert avail("1") == 1;
    assert lend("bob", "1", "2026-01-01")["ok"] == True;
    assert avail("1") == 0;
    assert lend("cy", "1", "2026-01-01")["ok"] == False;
}

test "no double borrowing and unknown books" {
    add("1", "A", 5);
    lend("ann", "1", "2026-01-01");
    assert lend("ann", "1", "2026-01-02")["ok"] == False;
    assert avail("1") == 4;
    assert lend("ann", "999", "2026-01-02")["ok"] == False;
    assert len([root -->[?:Member]]) == 1;
}

test "zero copies can never be lent" {
    add("1", "A", 0);
    assert lend("ann", "1", "2026-01-01")["ok"] == False;
}

test "returning frees a copy" {
    add("1", "A", 1);
    lend("ann", "1", "2026-01-01");
    assert back("ann", "1") == True;
    assert avail("1") == 1;
    assert lend("bob", "1", "2026-01-02")["ok"] == True;
}

test "bad returns" {
    add("1", "A", 1);
    assert back("ann", "1") == False;
    lend("ann", "1", "2026-01-01");
    assert back("bob", "1") == False;
    assert back("ann", "2") == False;
    assert back("ann", "1") == True;
    assert back("ann", "1") == False;
}

test "overdue is strictly before the given date" {
    add("1", "A", 1);
    lend("ann", "1", "2026-01-01");
    assert len((root spawn Overdue(date="2026-01-15")).reports[0]) == 0;
    rows = (root spawn Overdue(date="2026-01-16")).reports[0];
    assert len(rows) == 1;
    assert rows[0]["member"] == "ann";
    assert rows[0]["isbn"] == "1";
    assert rows[0]["due"] == "2026-01-15";
}

test "overdue sorted by due then member, returned loans excluded" {
    add("1", "A", 3);
    add("2", "B", 3);
    lend("zed", "1", "2026-01-01");
    lend("amy", "1", "2026-01-01");
    lend("bob", "2", "2025-12-20");
    lend("cat", "2", "2026-01-01");
    back("cat", "2");
    rows = (root spawn Overdue(date="2026-06-01")).reports[0];
    assert [(r["member"], r["isbn"]) for r in rows] == [("bob", "2"), ("amy", "1"), ("zed", "1")];
}
