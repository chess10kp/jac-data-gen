def nest_depth(tree: dict) -> int {
    deepest = 0;
    for value in tree.values() {
        if isinstance(value, dict) {
            child = nest_depth(value);
            if child > deepest {
                deepest = child;
            }
        }
    }
    return deepest + 1;
}

with entry {
    print(nest_depth({'a': 1, 'b': 2}));
}
