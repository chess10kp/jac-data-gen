def remove_whitespace(string: Any) -> object {
    if (string is None) {
        return None;
    }
    string_list = `list(string);
    length = len(string_list);
    count = 0;
    for i in range(length) {
        if (string_list[i] != ' ') {
            string_list[count] = string_list[i];
            count += 1;
        }
    }
    return "".join(string_list[:count]);
}



with entry {
    print(remove_whitespace('hello'));
    print(remove_whitespace('Racecar'));
    print(remove_whitespace('abcabc'));
}
