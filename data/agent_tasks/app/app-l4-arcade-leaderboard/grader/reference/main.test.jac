test "board keeps best per player" {
    root spawn submit_score(game="unit-galaga", player="zed", score=10);
    b = (root spawn submit_score(game="unit-galaga", player="ZED", score=5)).reports[0];
    zeds = [e for e in b if e["player"] == "ZED"];
    assert len(zeds) == 1;
    assert zeds[0]["score"] >= 10;
}

test "negative score rejected" {
    r = (root spawn submit_score(game="unit-galaga", player="neg", score=-1)).reports[0];
    assert r["error"] == "invalid score";
}
