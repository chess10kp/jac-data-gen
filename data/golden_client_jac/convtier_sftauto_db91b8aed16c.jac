def reverse_string(string: Any) -> object {
    reversed_str = "";
    for i in range((len(string) - 1), -1, -1) {
        reversed_str += string[i];
    }
    return reversed_str;
}



with entry {
    print(reverse_string('hello'));
    print(reverse_string('Racecar'));
    print(reverse_string('abcabc'));
}
