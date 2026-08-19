def add_items(n: Any) -> object {
    unique_items = `set();
    result = [];
    for i in range(n) {
        item = get_next_unique_item(unique_items, i);
        if (item is not None) {
            result.append(item);
        }
    }
    return result;
}



with entry {
    print(add_items(0));
}
