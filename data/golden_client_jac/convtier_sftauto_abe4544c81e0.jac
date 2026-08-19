def remove_vowels(sentence: Any) -> object {
    vowels = ['a', 'e', 'i', 'o', 'u', 'A', 'E', 'I', 'O', 'U'];
    modified_sentence = "";
    for char in sentence {
        if (char not in vowels) {
            modified_sentence += char;
        }
    }
    return modified_sentence;
}



with entry {
    print(remove_vowels('hello'));
    print(remove_vowels('Racecar'));
    print(remove_vowels('abcabc'));
}
