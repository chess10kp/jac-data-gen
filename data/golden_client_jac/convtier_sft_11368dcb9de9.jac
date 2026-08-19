def flatten_all(nested: list) -> list {
    flat = [];
    for item in nested {
        if isinstance(item, list) {
            flat.extend(flatten_all(item));
        } else {
            flat.append(item);
        }
    }
    return flat;
}

with entry {
    print(flatten_all([1, [2, [3, 4]], 5]));
}
