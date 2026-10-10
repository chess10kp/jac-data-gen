import from main { GetRequest }
test "boards malformed id fails before lookup" {
    res = root spawn GetRequest(
        param_name="board_id",
        param_value="bad-board-id"
    );

    assert res.status == 400, f"got {res.status}";
    assert res.body == "board_id must be a uuid", f"got {res.body}";
    assert "bad-board-id" not in res.body, f"echoed input: {res.body}";
    assert len([root-->]) == 0, f"store was touched: {len([root-->])}";
}

test "columns malformed id fails before lookup" {
    res = root spawn GetRequest(
        param_name="column_id",
        param_value="bad-column-id"
    );

    assert res.status == 400, f"got {res.status}";
    assert res.body == "column_id must be a uuid", f"got {res.body}";
    assert "bad-column-id" not in res.body, f"echoed input: {res.body}";
    assert len([root-->]) == 0, f"store was touched: {len([root-->])}";
}

test "cards malformed id fails before lookup" {
    res = root spawn GetRequest(
        param_name="card_id",
        param_value="bad-card-id"
    );

    assert res.status == 400, f"got {res.status}";
    assert res.body == "card_id must be a uuid", f"got {res.body}";
    assert "bad-card-id" not in res.body, f"echoed input: {res.body}";
    assert len([root-->]) == 0, f"store was touched: {len([root-->])}";
}

test "auth organization malformed id fails before lookup" {
    res = root spawn GetRequest(
        param_name="organization_id",
        param_value="bad-organization-id"
    );

    assert res.status == 400, f"got {res.status}";
    assert res.body == "organization_id must be a uuid", f"got {res.body}";
    assert "bad-organization-id" not in res.body, f"echoed input: {res.body}";
    assert len([root-->]) == 0, f"store was touched: {len([root-->])}";
}
