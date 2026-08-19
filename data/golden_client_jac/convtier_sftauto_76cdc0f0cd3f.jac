def calculate_length(string: Any) -> object {
    count = 0;
    for char in string {
        count += 1;
    }
    return count;
}



with entry {
    print(calculate_length('hello'));
    print(calculate_length('Racecar'));
    print(calculate_length('abcabc'));
}
