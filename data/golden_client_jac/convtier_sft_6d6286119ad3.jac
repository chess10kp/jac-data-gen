def _count(value: any) -> int {
    if isinstance(value, dict) {
        return sum([_count(v) for v in value.values()]);
    }
    if isinstance(value, list) {
        return sum([_count(v) for v in value]);
    }
    return 1;
}

def count_leaves(data: dict) -> int {
    return _count(data);
}

with entry {
    print(count_leaves({'a': [1, 2], 'b': {'c': 3}}));
}
