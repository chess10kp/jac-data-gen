def reverse_string(string: Any) -> object {
    reversed_string = "";
    for char in string {
        reversed_string = char + reversed_string;
    }
    return reversed_string;
}



with entry {
    print(reverse_string('hello'));
    print(reverse_string('Racecar'));
    print(reverse_string('abcabc'));
}
