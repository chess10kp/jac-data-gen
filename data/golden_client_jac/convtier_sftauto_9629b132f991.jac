def sort_string(string: str) -> str {
    string = string.strip();
    sorted_string = ''.join(sorted(string));
    return sorted_string;
}



with entry {
    print(sort_string('hello'));
    print(sort_string('Racecar'));
    print(sort_string('abcabc'));
}
