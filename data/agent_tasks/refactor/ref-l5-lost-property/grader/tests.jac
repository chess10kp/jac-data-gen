import from main { log_item, search, claim, claims_of, transfer, held_at, expire }

test "tags are numbered per station" {
    assert log_item("bag", "red", 1, "quay") == "quay-1";
    assert log_item("keys", "silver", 1, "quay") == "quay-2";
    assert log_item("phone", "black", 2, "park") == "park-1";
    assert log_item("hat", "red", 2, "park") == "";
    assert log_item("umbrella", "Red", 3, "quay") == "quay-3";
    assert held_at("quay") == ["quay-1", "quay-2", "quay-3"];
    assert held_at("park") == ["park-1"];
    assert len(held_at("mill")) == 0;
}

test "search matches category, colour and age, newest first" {
    log_item("umbrella", "red", 1, "quay");
    log_item("umbrella", "RED", 4, "park");
    log_item("umbrella", "blue", 5, "quay");
    log_item("bag", "red", 6, "quay");
    log_item("umbrella", "Red", 4, "mill");
    assert search("umbrella", "red", 0) == ["mill-1", "park-1", "quay-1"];
    assert search("umbrella", "red", 2) == ["mill-1", "park-1"];
    assert len(search("umbrella", "green", 0)) == 0;
    assert len(search("hat", "red", 0)) == 0;
}

test "claims hide items and are listed per person" {
    log_item("bag", "red", 1, "quay");
    log_item("bag", "red", 2, "quay");
    log_item("keys", "gold", 2, "park");
    assert claim("quay-2", "ines", 5) == "ok";
    assert claim("quay-2", "tom", 6) == "already claimed";
    assert claim("quay-9", "tom", 6) == "unknown item";
    assert claim("park-1", "ines", 7) == "ok";
    assert search("bag", "red", 0) == ["quay-1"];
    assert claims_of("ines") == ["park-1@7", "quay-2@5"];
    assert len(claims_of("tom")) == 0;
    assert held_at("quay") == ["quay-1"];
}

test "transfer moves only unclaimed items" {
    log_item("bag", "red", 1, "quay");
    log_item("bag", "red", 2, "quay");
    log_item("keys", "gold", 2, "park");
    claim("quay-1", "ines", 3);
    assert transfer("quay", "depot") == 1;
    assert transfer("quay", "depot") == 0;
    assert held_at("depot") == ["quay-2"];
    assert len(held_at("quay")) == 0;
    assert log_item("phone", "black", 4, "depot") == "depot-1";
    assert log_item("phone", "black", 4, "quay") == "quay-3";
    assert search("bag", "red", 0) == ["quay-2"];
    assert claim("quay-2", "tom", 5) == "ok";
    assert claims_of("tom") == ["quay-2@5"];
}

test "expiry disposes of old unclaimed items only" {
    log_item("bag", "red", 1, "quay");
    log_item("bag", "red", 5, "quay");
    log_item("keys", "gold", 2, "park");
    log_item("keys", "gold", 3, "park");
    claim("quay-1", "ines", 2);
    assert expire(10, 7) == ["park-1"];
    assert len(expire(10, 7)) == 0;
    assert expire(11, 5) == ["park-2", "quay-2"];
    assert claims_of("ines") == ["quay-1@2"];
    assert claim("park-1", "tom", 12) == "unknown item";
    assert log_item("keys", "gold", 12, "park") == "park-3";
    assert held_at("park") == ["park-3"];
}
