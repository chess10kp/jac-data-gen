def generate_all_permutations(nums: Any) -> object {
    permutations = [];
    def generate_permutations(
        current_permutation: Any, remaining_elements: Any
    ) -> object {
        if (len(remaining_elements) == 0) {
            permutations.append(current_permutation);
        } else {
            for i in range(len(remaining_elements)) {
                new_permutation = current_permutation + [remaining_elements[i]];
                new_remaining_elements = (
                    remaining_elements[:i] + remaining_elements[(i + 1):]
                );
                generate_permutations(new_permutation, new_remaining_elements);
            }
        }
    }
    generate_permutations([], sorted(nums));
    return permutations;
}



with entry {
    print(generate_all_permutations('hello'));
    print(generate_all_permutations('Racecar'));
    print(generate_all_permutations('abcabc'));
}
