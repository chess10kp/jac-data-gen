def remove_vowels(sentence: Any) -> object {
    vowels = 'aeiouAEIOU';
    result = '';
    for char in sentence {
        if (char not in vowels) {
            result += char;
        }
    }
    return result;
}



with entry {
    print(remove_vowels('hello'));
    print(remove_vowels('Racecar'));
    print(remove_vowels('abcabc'));
}
