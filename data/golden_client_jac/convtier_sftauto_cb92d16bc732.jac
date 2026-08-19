def calculate_string_length(string: Any) -> object {
    count = 0;
    for char in string {
        count += 1;
    }
    return count;
}



with entry {
    print(calculate_string_length('hello'));
    print(calculate_string_length('Racecar'));
    print(calculate_string_length('abcabc'));
}
