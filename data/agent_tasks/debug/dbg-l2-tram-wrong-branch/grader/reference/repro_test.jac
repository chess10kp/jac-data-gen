import from tramway { stop, add_hop, RunLine }

test "line 1 stays on line 1 at a branch" {
    add_hop("1", "Quay", "Market", 3);
    add_hop("2", "Market", "Depot", 5);
    add_hop("1", "Market", "Museum", 4);
    w = stop("Quay") spawn RunLine(line="1");
    assert w.reports[0] == ["Quay", "Market", "Museum"];
}
