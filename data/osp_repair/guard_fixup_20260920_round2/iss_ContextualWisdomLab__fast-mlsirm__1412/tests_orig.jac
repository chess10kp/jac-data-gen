test "selects closest and farthest retained cells by distance" {
    p1 = Person(pid="p1");
    p2 = Person(pid="p2");
    c1 = Cell(
        person_idx=0,
        item_idx=0,
        distance=0.25,
    );
    c2 = Cell(
        person_idx=0,
        item_idx=1,
        distance=1.00,
    );
    c3 = Cell(
        person_idx=1,
        item_idx=1,
        distance=2.00,
    );
    root +>:AnchorsPerson:+> p1;
    root +>:AnchorsPerson:+> p2;
    p1 +>:RetainsCell:+> c1;
    p1 +>:RetainsCell:+> c2;
    p2 +>:RetainsCell:+> c3;
    res = root spawn EnvelopeBuilder(requested_axes=2);
    assert res.min_key == "0:0", f"closest got {res.min_key}";
    assert res.max_key == "1:1", f"farthest got {res.max_key}";
    assert res.scored == 3, f"scored got {res.scored}";
    assert res.mapped == 3, f"mapped got {res.mapped}";
    assert res.finite_ok == True, f"finite_ok got {res.finite_ok}";
}

test "applies deterministic tie contract when distances are equal" {
    p1 = Person(pid="p1");
    p2 = Person(pid="p2");
    c_near = Cell(
        person_idx=0,
        item_idx=0,
        distance=1.0,
    );
    c_tie = Cell(
        person_idx=1,
        item_idx=0,
        distance=1.0,
    );
    root +>:AnchorsPerson:+> p1;
    root +>:AnchorsPerson:+> p2;
    p1 +>:RetainsCell:+> c_near;
    p2 +>:RetainsCell:+> c_tie;
    res = root spawn EnvelopeBuilder(requested_axes=2);
    assert res.min_key == "0:0", f"tie closest got {res.min_key}";
    assert res.max_key == "0:0", f"tie farthest got {res.max_key}";
    assert res.scored == 2, f"scored got {res.scored}";
    assert res.mapped == 2, f"mapped got {res.mapped}";
}

test "fails closed on non-finite cell distance with schema report" {
    p1 = Person(pid="p1");
    bad = Cell(
        person_idx=0,
        item_idx=0,
        distance=1e999,
    );
    root +>:AnchorsPerson:+> p1;
    p1 +>:RetainsCell:+> bad;
    res = root spawn EnvelopeBuilder(requested_axes=2);
    assert res.finite_ok == False, f"finite_ok got {res.finite_ok}";
    assert len(res.reports) == 1, f"reports got {res.reports}";
    r0 = res.reports[0];
    assert r0["schema_version"] == 1, f"schema_version got {r0}";
    assert r0["ok"] == False, f"ok got {r0}";
    assert r0["reason"] == "non-finite cell distance", f"reason got {r0}";
    assert r0["person_idx"] == 0, f"person_idx got {r0}";
    assert r0["item_idx"] == 0, f"item_idx got {r0}";
    assert res.scored == 0, f"scored got {res.scored}";
    assert res.mapped == 0, f"mapped got {res.mapped}";
}

test "single retained cell is both closest and farthest" {
    p1 = Person(pid="p1");
    only = Cell(
        person_idx=2,
        item_idx=3,
        distance=0.5,
    );
    root +>:AnchorsPerson:+> p1;
    p1 +>:RetainsCell:+> only;
    res = root spawn EnvelopeBuilder(requested_axes=2);
    assert res.min_key == "2:3", f"closest got {res.min_key}";
    assert res.max_key == "2:3", f"farthest got {res.max_key}";
    assert res.scored == 1, f"scored got {res.scored}";
    assert res.mapped == 1, f"mapped got {res.mapped}";
    assert res.finite_ok == True, f"finite_ok got {res.finite_ok}";
}

test "preserves requested axis count on walker" {
    p1 = Person(pid="p1");
    c1 = Cell(
        person_idx=0,
        item_idx=0,
        distance=0.1,
    );
    root +>:AnchorsPerson:+> p1;
    p1 +>:RetainsCell:+> c1;
    res = root spawn EnvelopeBuilder(requested_axes=2);
    assert res.requested_axes == 2, f"requested_axes got {res.requested_axes}";
    assert res.min_key == "0:0", f"closest got {res.min_key}";
    assert res.finite_ok == True, f"finite_ok got {res.finite_ok}";
}