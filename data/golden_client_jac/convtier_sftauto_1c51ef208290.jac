def remove_vowels(string: Any) -> object {
    vowels = 'aeiou';
    new_string = '';
    for char in string {
        if (char.lower() not in vowels) {
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
