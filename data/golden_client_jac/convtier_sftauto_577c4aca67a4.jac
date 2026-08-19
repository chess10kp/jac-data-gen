def is_vowel(character: Any) -> object {
    vowels = ['a', 'e', 'i', 'o', 'u'];
    return (character.lower() in vowels);
}



with entry {
    print(is_vowel('hello'));
}
