def calculate_length(lst: Any) -> object {
    count = 0;
    for _ in lst {
        count += 1;
    }
    return count;
}



with entry {
    print(calculate_length('hello'));
    print(calculate_length('Racecar'));
    print(calculate_length('abcabc'));
}
