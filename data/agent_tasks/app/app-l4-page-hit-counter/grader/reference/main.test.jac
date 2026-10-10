test "first visit counts one and repeat visits accumulate" {
    page = "/posts/test-hit-counter";
    first = (root spawn record_visit(page=page)).reports[0];
    again = (root spawn record_visit(page=page)).reports[0];
    assert first["page"] == page;
    assert again["visits"] == first["visits"] + 1;
}

test "blank page is rejected" {
    r = (root spawn record_visit(page="   ")).reports[0];
    assert r["error"] == "page required";
}
