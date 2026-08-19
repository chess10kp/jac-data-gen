def find_character_positions(string: Any) -> object {
    positions = {};
    for (i, char) in enumerate(string) {
        if char.isupper() {
            if (char in positions) {
                if (i not in positions[char]) {
                    positions[char].append(i);
                }
            } else {
                positions[char] = [i];
            }
        }
    }
    return positions;
}



with entry {
    print(find_character_positions('hello'));
    print(find_character_positions('Racecar'));
    print(find_character_positions('Hello, World!'));
}
