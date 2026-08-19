def example() -> dict {
    list_lit = [1, 2, 3];
    tuple_lit = (1, 2, 3);
    set_lit = {1, 2, 3};
    dict_lit = {"key": "value", "num": 42};
    empty_dict: dict = {};
    empty_list: list = [];

    # New: a nested collection literal
    nested = {"points": [(0, 0), (1, 2)], "tags": {"a", "b"}};
    return nested;
}

with entry {
    result = example();
    print(result["points"]);
}
