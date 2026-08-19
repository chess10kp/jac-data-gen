def reverse_string(input_str: Any) -> object {
    n = len(input_str);
    reversed_str = "";
    for i in range((n - 1), -1, -1) {
        reversed_str += input_str[i];
    }
    return reversed_str;
}



with entry {
    print(reverse_string('hello'));
    print(reverse_string('Racecar'));
    print(reverse_string('abcabc'));
}
