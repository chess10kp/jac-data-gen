def replace_vowels(word: Any) -> object {
    if not word {
        return '';
    }
    characters = `list(word);
    vowels = 'aeiouAEIOU';
    for (index, char) in enumerate(characters) {
        if ((char in vowels) and ((index % 2) != 0)) {
            characters[index] = '*';
        }
    }
    return ''.join(characters);
}



with entry {
    print(replace_vowels('hello'));
    print(replace_vowels('Racecar'));
    print(replace_vowels('abcabc'));
}
