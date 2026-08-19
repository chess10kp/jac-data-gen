def reverse_string_without_vowels(string: Any) -> object {
    vowels = ['a', 'e', 'i', 'o', 'u', 'A', 'E', 'I', 'O', 'U'];
    reverse_string = "";
    for char in reversed(string) {
        if (char not in vowels) {
            reverse_string += char;
        }
    }
    return reverse_string;
}



with entry {
    print(reverse_string_without_vowels('hello'));
    print(reverse_string_without_vowels('Racecar'));
    print(reverse_string_without_vowels('abcabc'));
}
