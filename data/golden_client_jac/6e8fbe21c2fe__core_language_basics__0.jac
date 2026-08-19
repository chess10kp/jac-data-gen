def example(my_list: list | None, config: dict | None) {
    # Without null-safe: raises TypeError if list is None
    item = my_list[0];

    # With null-safe: returns None if list is None
    item = my_list?[0];

    # Works with dictionaries too
    value = config?["key"];

    # Also handles out-of-bounds indices
    items = [1, 2, 3];
    result = items?[10];         # None (no IndexError)

    # And missing dictionary keys
    data = {"a": 1};
    result = data?["missing"];   # None (no KeyError)
}
