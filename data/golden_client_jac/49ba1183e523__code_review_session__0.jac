import from typing { Generator }

def flatten(nested: list) -> Generator[any, None, None] {
    for item in nested {
        if isinstance(item, list) {
            yield from flatten(item);  # Delegate to sub-generator
        } else {
            yield item;
        }
    }
}

with entry {
    nested = [[1, 2], [3, [4, 5]], 6];
    flat = list(flatten(nested));
    print(flat);  # [1, 2, 3, 4, 5, 6]
}
