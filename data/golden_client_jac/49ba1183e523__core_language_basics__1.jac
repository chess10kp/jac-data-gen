def flatten(nested: list) -> any {
    for item in nested {
        if isinstance(item, list) {
            yield from flatten(item);  # Delegate to sub-generator
        } else {
            yield item;
        }
    }
}

with entry {
    # Usage
    nested = [[1, 2], [3, [4, 5]], 6];
    flat = list(flatten(nested));  # [1, 2, 3, 4, 5, 6]
}
