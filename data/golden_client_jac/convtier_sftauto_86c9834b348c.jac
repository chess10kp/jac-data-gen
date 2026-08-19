def is_vowel(char: Any) -> object {
    vowels = ['a', 'e', 'i', 'o', 'u'];
    return (char.lower() in vowels);
}



with entry {
    print(is_vowel('hello'));
}
