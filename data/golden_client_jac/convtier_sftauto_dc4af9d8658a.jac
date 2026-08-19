def reverse_string(s: Any) -> object {
    reversed_str = "";
    for i in range((len(s) - 1), -1, -1) {
        reversed_str += s[i];
    }
    return reversed_str;
}



with entry {
    print(reverse_string('hello'));
    print(reverse_string('Racecar'));
    print(reverse_string('abcabc'));
}
