def group_strings(strings: Any) -> object {
    string_dict = {};
    for string in strings {
        key = string[:2];
        if (key not in string_dict) {
            string_dict[key] = [];
        }
        string_dict[key].append(string);
    }
    for key in string_dict {
        string_dict[key] = sorted(`list(`set(string_dict[key])));
    }
    return string_dict;
}



with entry {
    print(group_strings('hello'));
    print(group_strings('Racecar'));
    print(group_strings('abcabc'));
}
