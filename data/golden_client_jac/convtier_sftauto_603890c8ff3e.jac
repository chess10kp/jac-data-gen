def is_vowel(ch: Any) -> object {
    vowels = {'a', 'e', 'i', 'o', 'u'};
    return (ch.lower() in vowels);
}



with entry {
    print(is_vowel('hello'));
}
