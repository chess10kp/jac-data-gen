def process_strings(string_list: Any) -> object {
    string_list = [string.lower() for string in string_list];
    string_list = `list(`set(string_list));
    string_list.sort();
    return string_list;
}



with entry {
    print(process_strings('hello'));
    print(process_strings('Racecar'));
    print(process_strings('abcabc'));
}
