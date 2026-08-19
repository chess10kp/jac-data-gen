def reverse_string(input_str: Any) -> object {
    return input_str[::-1];
}



with entry {
    print(reverse_string('hello'));
    print(reverse_string('Racecar'));
    print(reverse_string('abcabc'));
}
