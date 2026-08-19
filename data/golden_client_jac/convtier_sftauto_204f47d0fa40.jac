def generate_permutations(s: Any) -> object {
    permutations = [s[0]];
    for i in range(1, len(s)) {
        char = s[i];
        new_permutations = [];
        for permutation in permutations {
            for j in range((len(permutation) + 1)) {
                new_permutations.append((permutation[:j] + char + permutation[j:]));
            }
        }
        permutations = new_permutations;
    }
    return sorted(permutations);
}



with entry {
    print(generate_permutations('hello'));
    print(generate_permutations('Racecar'));
    print(generate_permutations('abcabc'));
}
