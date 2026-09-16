import from solution { Request, AllocationResult, allocate_requests }

# R9: empty input -> empty result, no capacity used.
test "empty input yields empty result" {
    res = allocate_requests([], 5);
    assert len(res.accepted) == 0;
    assert len(res.rejected) == 0;
    assert res.used == 0;
}

# R1/R6/R7: fitting positive new requests accepted in order; used == sum.
test "exact capacity accepted in input order" {
    reqs = [Request(id="a", count=3), Request(id="b", count=2)];
    res = allocate_requests(reqs, 5);
    assert res.accepted == ["a", "b"];
    assert len(res.rejected) == 0;
    assert res.used == 5;
}

# R6 (kills sort mutants): input order must win even when it differs from
# lexicographic order -- every earlier order test used alphabetical ids.
test "input order wins over lexicographic order" {
    reqs = [Request(id="b", count=1), Request(id="a", count=1), Request(id="c", count=1)];
    res = allocate_requests(reqs, 5);
    assert res.accepted == ["b", "a", "c"];
    assert len(res.rejected) == 0;
    assert res.used == 3;
}

# R2: zero and negative counts are invalid; valid ones still accepted.
test "invalid counts rejected, valid still accepted" {
    reqs = [Request(id="a", count=0), Request(id="b", count=-1), Request(id="c", count=2)];
    res = allocate_requests(reqs, 5);
    assert res.accepted == ["c"];
    assert res.rejected == ["a", "b"];
    assert res.used == 2;
}

# R3: a second occurrence of an already-accepted id is a duplicate.
test "duplicate of accepted id rejected" {
    reqs = [Request(id="a", count=2), Request(id="a", count=1)];
    res = allocate_requests(reqs, 10);
    assert res.accepted == ["a"];
    assert res.rejected == ["a"];
    assert res.used == 2;
}

# R4: a non-fitting request must not stop a later smaller fitting request.
test "non-fitting request does not stop later fitting request" {
    reqs = [Request(id="a", count=3), Request(id="big", count=10), Request(id="d", count=2)];
    res = allocate_requests(reqs, 5);
    assert res.accepted == ["a", "d"];
    assert res.rejected == ["big"];
    assert res.used == 5;
}

# R5 (disambiguation): an id whose FIRST occurrence was rejected (invalid or
# non-fitting) is NOT thereby a duplicate; a later valid occurrence is accepted.
test "rejected first occurrence does not block later valid same id" {
    reqs = [Request(id="a", count=0), Request(id="a", count=2)];
    res = allocate_requests(reqs, 5);
    assert res.accepted == ["a"];
    assert res.rejected == ["a"];
    assert res.used == 2;
}

# R10: zero capacity rejects every positive request.
test "zero capacity rejects all positive requests" {
    reqs = [Request(id="a", count=1), Request(id="b", count=1)];
    res = allocate_requests(reqs, 0);
    assert len(res.accepted) == 0;
    assert res.rejected == ["a", "b"];
    assert res.used == 0;
}

# R8: the caller's list and objects are not mutated.
test "input list and objects are not mutated" {
    reqs = [Request(id="a", count=3), Request(id="b", count=9)];
    allocate_requests(reqs, 5);
    assert len(reqs) == 2;
    assert reqs[0].id == "a";
    assert reqs[0].count == 3;
    assert reqs[1].count == 9;
}

# Interaction: full sweep touching duplicate + overflow + recovery together.
test "mixed sweep preserves order and used total" {
    reqs = [
        Request(id="x", count=4),
        Request(id="x", count=1),
        Request(id="y", count=5),
        Request(id="z", count=1)
    ];
    res = allocate_requests(reqs, 5);
    assert res.accepted == ["x", "z"];
    assert res.rejected == ["x", "y"];
    assert res.used == 5;
}
