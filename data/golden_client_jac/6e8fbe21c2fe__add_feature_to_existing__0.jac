def example(my_list: list | None, config: dict | None) -> None {
    item = my_list?[0];
    value = config?["key"];

    items = [1, 2, 3];
    result = items?[10];

    data = {"a": 1};
    result = data?["missing"];

    # New: null-safe index with a fallback default
    first = my_list?[0] if my_list else "empty";
    print(first);
}

with entry {
    example(None, None);
    example([10, 20], {"key": "v"});
}
