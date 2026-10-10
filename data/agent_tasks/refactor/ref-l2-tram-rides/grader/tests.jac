import from tramway { add_hop, ride, ride_minutes, is_loop }

def network {
    add_hop("1", "Depot", "Market", 3);
    add_hop("1", "Market", "Bridge", 4);
    add_hop("1", "Bridge", "Harbour", 6);
    add_hop("2", "Market", "Park", 2);
    add_hop("2", "Park", "Uni", 5);
    add_hop("2", "Uni", "Market", 7);
    add_hop("3", "Bridge", "Market", 1);
}

test "hops are validated and lines never branch" {
    assert add_hop("1", "A", "B", 3);
    assert not add_hop("1", "A", "C", 3);
    assert add_hop("2", "A", "C", 3);
    assert not add_hop("1", "B", "B", 2);
    assert not add_hop("1", "B", "C", 0);
    assert add_hop("1", "B", "C", 2);
}

test "riding a line to its end" {
    network();
    assert ride("1", "Depot") == ["Depot", "Market", "Bridge", "Harbour"];
    assert ride_minutes("1", "Depot") == 13;
    assert ride("1", "Bridge") == ["Bridge", "Harbour"];
    assert ride_minutes("1", "Bridge") == 6;
    assert not is_loop("1", "Depot");
    assert ride("1", "Harbour") == ["Harbour"];
    assert ride_minutes("1", "Harbour") == 0;
}

test "other lines' tracks are ignored" {
    network();
    assert ride("2", "Depot") == ["Depot"];
    assert ride("3", "Bridge") == ["Bridge", "Market"];
    assert ride_minutes("3", "Bridge") == 1;
    assert ride("2", "Park") == ["Park", "Uni", "Market"];
    assert ride("1", "Park") == ["Park"];
}

test "loops stop at the first repeated stop and count the closing hop" {
    network();
    assert ride("2", "Market") == ["Market", "Park", "Uni"];
    assert ride_minutes("2", "Market") == 14;
    assert is_loop("2", "Market");
    assert is_loop("2", "Uni");
    assert not is_loop("3", "Bridge");
}

test "unknown stops ride nowhere" {
    network();
    assert len(ride("1", "Nowhere")) == 0;
    assert ride_minutes("1", "Nowhere") == 0;
    assert not is_loop("1", "Nowhere");
}
