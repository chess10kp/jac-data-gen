def find_string_length(s: Any) -> object {
    count = 0;
    for _ in s {
        count += 1;
    }
    return count;
}



with entry {
    print(find_string_length('hello'));
    print(find_string_length('Racecar'));
    print(find_string_length('abcabc'));
}
