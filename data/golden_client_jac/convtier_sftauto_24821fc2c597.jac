def letter_frequency(string: Any) -> object {
    frequency = {};
    string = string.lower();
    for char in string {
        if ((char not in "aeiou") and char.isalpha()) {
            frequency[char] = frequency.get(char, 0) + 1;
        }
    }
    return frequency;
}



with entry {
    print(letter_frequency('hello'));
    print(letter_frequency('Racecar'));
    print(letter_frequency('abcabc'));
}
