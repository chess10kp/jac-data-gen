def count_vowels(string: Any) -> object {
    vowels = {'a': 0, 'e': 0, 'i': 0, 'o': 0, 'u': 0};
    vowel_positions = {};
    for (i, char) in enumerate(string) {
        if char.isalpha() {
            char_lower = char.lower();
            if (char_lower in vowels) {
                vowels[char_lower] += 1;
                if (char_lower not in vowel_positions) {
                    vowel_positions[char_lower] = [];
                }
                vowel_positions[char_lower].append(i);
            }
        }
    }
    return vowel_positions if vowel_positions else {};
}



with entry {
    print(count_vowels('hello'));
    print(count_vowels('Racecar'));
    print(count_vowels('abcabc'));
}
