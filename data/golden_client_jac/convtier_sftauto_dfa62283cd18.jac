def is_vowel(letter: Any) -> object {
    vowels = ['a', 'e', 'i', 'o', 'u'];
    return (letter.lower() in vowels);
}



with entry {
    print(is_vowel('hello'));
}
