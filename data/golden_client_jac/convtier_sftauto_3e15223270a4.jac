def inverse_string(input_string: Any) -> object {
    inverse = "";
    for i in range((len(input_string) - 1), -1, -1) {
        inverse += input_string[i];
    }
    return inverse;
}



with entry {
    print(inverse_string('hello'));
    print(inverse_string('Racecar'));
    print(inverse_string('abcabc'));
}
