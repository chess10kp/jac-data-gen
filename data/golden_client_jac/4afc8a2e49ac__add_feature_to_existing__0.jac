test "double toggle" {
    create = _call("walker", "create_todo", {"text": "x"});
    node_id = _first_todo(create)["_jac_id"];
    _call("walker", "toggle_todo", {}, anchor=node_id);
    _call("walker", "toggle_todo", {}, anchor=node_id);
    assert _first_todo(create)["done"] == False;
}
