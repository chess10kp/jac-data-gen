def reverse_string_without_vowels(original_string: Any) -> object {
    vowels = ['a', 'e', 'i', 'o', 'u', 'A', 'E', 'I', 'O', 'U'];
    reversed_string = "";
    for char in original_string[::-1] {
        if (char not in vowels) {
            reversed_string += char;
        }
    }
    return reversed_string;
}



with entry {
    print(reverse_string_without_vowels('hello'));
    print(reverse_string_without_vowels('Racecar'));
    print(reverse_string_without_vowels('abcabc'));
}
