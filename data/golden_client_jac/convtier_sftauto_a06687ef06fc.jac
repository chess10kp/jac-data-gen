def reverse_string(string: Any) -> object {
    length = len(string);
    reversed_string = "";
    for i in range((length - 1), -1, -1) {
        reversed_string += string[i];
    }
    return reversed_string;
}



with entry {
    print(reverse_string('hello'));
    print(reverse_string('Racecar'));
    print(reverse_string('abcabc'));
}
