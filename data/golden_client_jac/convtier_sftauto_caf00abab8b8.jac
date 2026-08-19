def identify_next_number(sequence: Any) -> object {
    next_number = sequence[-1] * 2;
    return next_number;
}



with entry {
    print(identify_next_number('hello'));
    print(identify_next_number('Racecar'));
    print(identify_next_number('abcabc'));
}
