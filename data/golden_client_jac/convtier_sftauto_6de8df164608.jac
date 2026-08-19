def reverse_string(input_str: Any) -> object {
    reversed_str = "";
    for char in input_str[::-1] {
        reversed_str += char;
    }
    return reversed_str;
}



with entry {
    print(reverse_string('hello'));
    print(reverse_string('Racecar'));
    print(reverse_string('abcabc'));
}
