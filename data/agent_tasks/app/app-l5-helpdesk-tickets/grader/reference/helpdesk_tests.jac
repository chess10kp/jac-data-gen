import from main { open_ticket, assign_ticket, add_comment, close_ticket, list_tickets }

test "ticket lifecycle" {
    t = (root spawn open_ticket(subject="printer jam", priority="low")).reports[0];
    n = t["number"];
    assert t["status"] == "open" and t["agent"] == "";
    assert "error" in (root spawn close_ticket(number=n)).reports[0];
    root spawn assign_ticket(number=n, agent="kim");
    c = (root spawn add_comment(number=n, author="kim", body="cleared")).reports[0];
    assert c["comments"][-1]["body"] == "cleared";
    done = (root spawn close_ticket(number=n)).reports[0];
    assert done["status"] == "closed";
    assert "error" in (root spawn add_comment(number=n, author="x", body="y")).reports[0];
}

test "validation" {
    assert "error" in (root spawn open_ticket(subject="", priority="low")).reports[0];
    assert "error" in (root spawn open_ticket(subject="x", priority="urgent")).reports[0];
    assert "error" in (root spawn assign_ticket(number=999999, agent="kim")).reports[0];
}
