def get_character_indices(string: Any) -> object {
    character_indices = {};
    for (index, character) in enumerate(string) {
        if (character not in character_indices) {
            character_indices[character] = [index];
        } else {
            character_indices[character].append(index);
        }
    }
    return character_indices;
}



with entry {
    print(get_character_indices('hello'));
    print(get_character_indices('Racecar'));
    print(get_character_indices('abcabc'));
}
