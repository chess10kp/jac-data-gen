def find_last_vowel(string: Any) -> object {
    vowels = ['a', 'e', 'i', 'o', 'u'];
    if not string {
        return None;
    }
    if (string[-1] in vowels) {
        return string[-1];
    }
    return find_last_vowel(string[:-1]);
}



with entry {
    print(find_last_vowel('hello'));
    print(find_last_vowel(['a']));
}
