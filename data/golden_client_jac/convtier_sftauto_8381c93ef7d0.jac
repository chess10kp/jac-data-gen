def reverse_string(input_str: Any) -> object {
    reversed_str = '';
    for char in input_str {
        if char.isalpha() {
            if char.islower() {
                reversed_str = char.upper() + reversed_str;
            } else {
                reversed_str = char.lower() + reversed_str;
            }
        } else {
            reversed_str = char + reversed_str;
        }
    }
    return reversed_str;
}



with entry {
    print(reverse_string('hello'));
    print(reverse_string('Racecar'));
    print(reverse_string('abcabc'));
}
