def reverse_string(s: Any) -> object {
    reversed_string = '';
    for i in range((len(s) - 1), -1, -1) {
        reversed_string += s[i];
    }
    return reversed_string;
}



with entry {
    print(reverse_string('hello'));
    print(reverse_string('Racecar'));
    print(reverse_string('abcabc'));
}
