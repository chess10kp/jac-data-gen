def count_vowels(string: Any) -> object {
    vowels = {'a': 0, 'e': 0, 'i': 0, 'o': 0, 'u': 0};
    vowels_positions = {'a': [], 'e': [], 'i': [], 'o': [], 'u': []};
    for (i, char) in enumerate(string) {
        if (char.lower() in vowels) {
            vowels[char.lower()] += 1;
            vowels_positions[char.lower()].append(i);
        }
    }
    return {'count': vowels, 'positions': vowels_positions};
}



with entry {
    print(count_vowels('hello'));
    print(count_vowels('Racecar'));
    print(count_vowels('abcabc'));
}
