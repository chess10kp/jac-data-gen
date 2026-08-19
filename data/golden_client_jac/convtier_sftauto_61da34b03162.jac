def first_non_consonant_vowel(string: Any) -> object {
    vowels = ['a', 'e', 'i', 'o', 'u'];
    for i in range((len(string) - 1)) {
        if (
            (string[i].lower() in vowels) and (string[(i + 1)].lower() not in vowels)
        ) {
            return i;
        }
    }
    return -1;
}



with entry {
    print(first_non_consonant_vowel('hello'));
    print(first_non_consonant_vowel('abcabc'));
    print(first_non_consonant_vowel('step on no pets'));
}
