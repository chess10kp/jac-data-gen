def find_max_depth(dictionary: Any) -> object {
    if not isinstance(dictionary, `dict) {
        return 0;
    }
    max_depth = 0;
    for value in dictionary.values() {
        depth = 1 + find_max_depth(value);
        max_depth = max(max_depth, depth);
    }
    return max_depth;
}



with entry {
    print(find_max_depth('hello'));
}
