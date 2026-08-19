def generate_permutations(word: Any) -> object {
    if (len(word) == 1) {
        return [word];
    }
    permutations = [];
    for i in range(len(word)) {
        for perm in generate_permutations((word[:i] + word[(i + 1):])) {
            permutations.append((word[i] + perm));
        }
    }
    return permutations;
}



with entry {
    print(generate_permutations([]));
}
