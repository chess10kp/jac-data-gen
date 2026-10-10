import from main { AddBook, Checkout, Available }

test "checkout uses up the only copy" {
    root spawn AddBook(isbn="repro-1", title="Ulysses", copies=1);
    root spawn Checkout(member="ann", isbn="repro-1", date="2026-04-01");
    assert (root spawn Available(isbn="repro-1")).reports[0] == 0;
}
