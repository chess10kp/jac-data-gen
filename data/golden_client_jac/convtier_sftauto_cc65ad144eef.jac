def remove_vowels(s: Any) -> object {
    vowels = "aeiouAEIOU";
    new_string = "";
    for char in s {
        if (char not in vowels) {
            new_string += char;
        }
    }
    return new_string;
}



with entry {
    print(remove_vowels('hello'));
    print(remove_vowels('Racecar'));
    print(remove_vowels('abcabc'));
}
