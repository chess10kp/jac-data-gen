test "booking fills a class and then refuses" {
    c = create_class("unit-yoga", 1);
    b = book_spot(c["id"], "ana");
    assert b["booked"] == 1 and b["spots_left"] == 0;
    assert "error" in list(book_spot(c["id"], "ben"));
}

test "double booking and bad cancel are errors" {
    c = create_class("unit-boulder", 3);
    book_spot(c["id"], "ana");
    assert "error" in list(book_spot(c["id"], "ana"));
    assert "error" in list(cancel_booking(c["id"], "zed"));
    assert cancel_booking(c["id"], "ana")["booked"] == 0;
}

test "capacity validated" {
    assert "error" in list(create_class("unit-bad", 0));
}
