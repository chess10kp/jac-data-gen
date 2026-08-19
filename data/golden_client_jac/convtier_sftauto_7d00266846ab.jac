def generate_subsets(input_set: Any) -> object {
    input_set = sorted(input_set);
    n = len(input_set);
    subsets = [];
    for size in range(1, (n + 1)) {
        generate_subsets_util(input_set, size, 0, [], subsets);
    }
    return subsets;
}



with entry {
    print(generate_subsets([]));
}
