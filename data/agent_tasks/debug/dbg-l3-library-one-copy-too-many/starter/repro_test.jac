import from main { AddBook, Checkout, Available }

test "no checkout once the only copy is out" {
    root spawn AddBook(isbn="repro-1", title="Ulysses", copies=1);
    root spawn Checkout(member="ann", isbn="repro-1", date="2026-04-01");
    r = root spawn Checkout(member="bob", isbn="repro-1", date="2026-04-02");
    assert r.reports[0]["ok"] == False;
    assert (root spawn Available(isbn="repro-1")).reports[0] == 0;
}
