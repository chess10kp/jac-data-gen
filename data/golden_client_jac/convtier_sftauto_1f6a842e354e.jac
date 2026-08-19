def remove_duplicates(input_string: Any) -> object {
    seen = '';
    result = '';
    for char in input_string {
        if (char == ' ') {
            if (seen not in result) {
                result += seen + ' ';
            }
            seen = '';
        } else {
            seen += char;
        }
    }
    if (seen not in result) {
        result += seen;
    }
    return result.rstrip();
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
