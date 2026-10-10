import from tramway { Stop, Track, stop, add_hop, RunLine, Interchanges }

test "straight run to the end of the line" {
    add_hop("1", "Quay", "Market", 3);
    add_hop("1", "Market", "Museum", 4);
    add_hop("1", "Museum", "Park", 2);
    w = stop("Quay") spawn RunLine(line="1");
    assert len(w.reports) == 1;
    assert w.reports[0] == ["Quay", "Market", "Museum", "Park"];
    assert w.minutes == 9;
}

test "run starting mid line" {
    add_hop("1", "Quay", "Market", 3);
    add_hop("1", "Market", "Museum", 4);
    w = stop("Market") spawn RunLine(line="1");
    assert w.reports[0] == ["Market", "Museum"];
    assert w.minutes == 4;
}

test "only the requested line is ridden at a branching stop" {
    add_hop("1", "Quay", "Market", 3);
    add_hop("2", "Market", "Depot", 5);
    add_hop("1", "Market", "Museum", 4);
    add_hop("2", "Quay", "Beach", 7);
    w = stop("Quay") spawn RunLine(line="1");
    assert w.reports[0] == ["Quay", "Market", "Museum"];
    assert w.minutes == 7;
    w2 = stop("Market") spawn RunLine(line="2");
    assert w2.reports[0] == ["Market", "Depot"];
}

test "loop line stops before revisiting and skips closing hop minutes" {
    add_hop("C", "A", "B", 1);
    add_hop("C", "B", "C", 2);
    add_hop("C", "C", "A", 10);
    w = stop("B") spawn RunLine(line="C");
    assert w.reports[0] == ["B", "C", "A"];
    assert w.minutes == 12;
}

test "unknown line rides nowhere" {
    add_hop("1", "Quay", "Market", 3);
    w = stop("Quay") spawn RunLine(line="9");
    assert w.reports[0] == ["Quay"];
    assert w.minutes == 0;
}

test "interchanges count arriving and departing lines" {
    add_hop("1", "Quay", "Market", 3);
    add_hop("1", "Market", "Museum", 4);
    add_hop("2", "Depot", "Museum", 5);
    add_hop("2", "Museum", "Zoo", 5);
    add_hop("3", "Beach", "Quay", 6);
    add_hop("1", "Beach", "Pier", 1);
    w = root spawn Interchanges();
    assert len(w.reports) == 1;
    assert w.reports[0] == ["Beach", "Museum", "Quay"];
}

test "same line twice is not an interchange" {
    add_hop("1", "Quay", "Market", 3);
    add_hop("1", "Market", "Museum", 4);
    w = root spawn Interchanges();
    assert len(w.reports[0]) == 0;
}
