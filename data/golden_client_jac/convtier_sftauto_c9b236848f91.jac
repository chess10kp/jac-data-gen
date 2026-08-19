def generate_combinations(string: Any) -> object {
    chars = `list(string);
    combinations = [];
    for r in range(1, (len(chars) + 1)) {
        combinations.extend(
            [''.join(comb) for comb in itertools.product(chars, repeat=r)]
        );
    }
    return combinations;
}



with entry {
    print(generate_combinations([]));
}
