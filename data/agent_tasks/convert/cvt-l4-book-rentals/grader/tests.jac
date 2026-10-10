import uuid;
import from rentals {
    Book, Person, Rental, Rents, RentalOf,
    create_book, get_book, get_available_books, check_availability, create_person, get_person,
    create_rental, get_rental, get_all_rentals, return_book, check_overdue
}

def run(w: Walker) -> any {
    return (root spawn w).reports[0];
}

def book(t: str, avail: int, total: int) -> dict[str, any] {
    return dict(run(create_book(title=t, description="d", author="Orwell", available_copies=avail, total_copies=total)));
}

def person(n: str) -> dict[str, any] {
    return dict(run(create_person(name=n, age=30, email=n + "@mail.com")));
}

test "books validate copies and are found by id" {
    t = uuid.uuid4().hex[:8];
    b = book("1984 " + t, 2, 3);
    assert b["available_copies"] == 2 and b["total_copies"] == 3 and b["author"] == "Orwell";
    assert dict(run(get_book(book_id=b["id"])))["title"] == "1984 " + t;
    bad = dict(run(create_book(title="Bad " + t, description="d", author="x", available_copies=5, total_copies=1)));
    assert bad["status"] == 422;
    assert len([x for x in [root -->[?:Book]] if x.title == "Bad " + t]) == 0;
    missing = dict(run(get_book(book_id="nope")));
    assert missing["status"] == 404 and missing["detail"] == "Book with ID nope not found";
}

test "availability and available listing" {
    t = uuid.uuid4().hex[:8];
    a = book("free " + t, 1, 1);
    z = book("none " + t, 0, 2);
    assert run(check_availability(book_id=a["id"])) == True;
    assert run(check_availability(book_id=z["id"])) == False;
    assert run(check_availability(book_id="ghost")) == False;
    ids = [x["id"] for x in run(get_available_books())];
    assert a["id"] in ids and z["id"] not in ids;
}

test "renting decrements copies and links person, rental and book" {
    t = uuid.uuid4().hex[:8];
    b = book("Dune " + t, 2, 2);
    p = person("ann" + t);
    r = dict(run(create_rental(book_id=b["id"], person_id=p["id"], due_date="2999-01-01T00:00:00")));
    assert r["status"] == "active" and r["book_id"] == b["id"] and r["person_id"] == p["id"];
    assert r["return_date"] is None and r["due_date"] == "2999-01-01T00:00:00" and len(r["rental_date"]) > 0;
    assert dict(run(get_book(book_id=b["id"])))["available_copies"] == 1;
    pn = [x for x in [root -->[?:Person]] if jid(x) == p["id"]][0];
    rn = [x for x in [pn ->:Rents:->]];
    assert len(rn) == 1 and [k.title for k in [rn[0] ->:RentalOf:->]] == ["Dune " + t];
    d = dict(run(get_rental(rental_id=r["id"])));
    assert d["book_title"] == "Dune " + t and d["person_name"] == "ann" + t and d["person_email"] == "ann" + t + "@mail.com";
    assert r["id"] in [x["id"] for x in run(get_all_rentals(limit=100000))];
}

test "rental refused when sold out or unknown" {
    t = uuid.uuid4().hex[:8];
    b = book("Solo " + t, 1, 1);
    p = person("bo" + t);
    q = person("cy" + t);
    assert dict(run(create_rental(book_id=b["id"], person_id=p["id"], due_date="2999-01-01")))["status"] == "active";
    out = dict(run(create_rental(book_id=b["id"], person_id=q["id"], due_date="2999-01-01")));
    assert out["status"] == 409 and out["detail"] == "Book 'Solo " + t + "' is not available for rental";
    assert dict(run(get_book(book_id=b["id"])))["available_copies"] == 0;
    assert dict(run(create_rental(book_id="ghost", person_id=p["id"], due_date="2999-01-01")))["status"] == 404;
    b2 = book("Other " + t, 1, 1);
    nobody = dict(run(create_rental(book_id=b2["id"], person_id="ghost", due_date="2999-01-01")));
    assert nobody["status"] == 404 and nobody["detail"] == "Person with ID ghost not found";
    assert dict(run(get_book(book_id=b2["id"])))["available_copies"] == 1;
    qn = [x for x in [root -->[?:Person]] if jid(x) == q["id"]][0];
    assert len([x for x in [qn ->:Rents:->]]) == 0;
}

test "return restores the copy" {
    t = uuid.uuid4().hex[:8];
    b = book("Back " + t, 1, 1);
    p = person("di" + t);
    r = dict(run(create_rental(book_id=b["id"], person_id=p["id"], due_date="2999-01-01")));
    back = dict(run(return_book(rental_id=r["id"])));
    assert back["status"] == "returned" and back["return_date"] is not None;
    assert dict(run(get_book(book_id=b["id"])))["available_copies"] == 1;
    assert dict(run(get_rental(rental_id=r["id"])))["status"] == "returned";
    assert dict(run(return_book(rental_id="ghost")))["status"] == 404;
}

test "overdue sweep marks only active past-due rentals" {
    t = uuid.uuid4().hex[:8];
    b = book("Late " + t, 3, 3);
    p = person("ed" + t);
    late = dict(run(create_rental(book_id=b["id"], person_id=p["id"], due_date="2001-01-01T00:00:00")));
    fine = dict(run(create_rental(book_id=b["id"], person_id=p["id"], due_date="2999-01-01T00:00:00")));
    done = dict(run(create_rental(book_id=b["id"], person_id=p["id"], due_date="2001-01-01T00:00:00")));
    run(return_book(rental_id=done["id"]));
    msgs = [m for m in run(check_overdue(now="2020-06-01T00:00:00")) if m["rental_id"] in [late["id"], fine["id"], done["id"]]];
    assert len(msgs) == 1 and msgs[0]["rental_id"] == late["id"];
    assert msgs[0]["type"] == "overdue" and msgs[0]["book_title"] == "Late " + t and msgs[0]["person_email"] == "ed" + t + "@mail.com";
    assert dict(run(get_rental(rental_id=late["id"])))["status"] == "overdue";
    assert dict(run(get_rental(rental_id=fine["id"])))["status"] == "active";
    assert dict(run(get_rental(rental_id=done["id"])))["status"] == "returned";
    again = [m for m in run(check_overdue(now="2020-06-01T00:00:00")) if m["rental_id"] == late["id"]];
    assert len(again) == 0;
}

test "people" {
    t = uuid.uuid4().hex[:8];
    p = dict(run(create_person(name="fe" + t, age=41, email="fe@x.io", phone="555")));
    g = dict(run(get_person(person_id=p["id"])));
    assert g["age"] == 41 and g["phone"] == "555" and g["address"] is None;
    assert dict(run(get_person(person_id="ghost")))["status"] == 404;
}
