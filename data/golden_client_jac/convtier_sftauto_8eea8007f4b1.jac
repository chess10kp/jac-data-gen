def append_string(string: Any) -> object {
    result = '';
    for i in range(len(string)) {
        result += string[i] * (i + 1);
    }
    return (result + string);
}



with entry {
    print(append_string('hello'));
    print(append_string('Racecar'));
    print(append_string('abcabc'));
}
