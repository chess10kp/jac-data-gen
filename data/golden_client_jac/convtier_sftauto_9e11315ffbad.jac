def reverse_string(input_string: Any) -> object {
    reversed_string = '';
    for i in range((len(input_string) - 1), -1, -1) {
        reversed_string += input_string[i];
    }
    return reversed_string;
}



with entry {
    print(reverse_string('hello'));
    print(reverse_string('Racecar'));
    print(reverse_string('abcabc'));
}
