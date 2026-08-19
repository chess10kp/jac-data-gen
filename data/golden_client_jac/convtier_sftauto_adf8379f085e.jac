def convert_list_to_dict(lst: Any) -> object {
    `dict = {};
    for string in lst {
        key = string.lower();
        if (key in `dict) {
            `dict[key].append(string);
        } else {
            `dict[key] = [string];
        }
    }
    sorted_keys = sorted(`dict.keys(), reverse=True);
    sorted_dict = {key: `dict[key] for key in sorted_keys};
    return sorted_dict;
}



with entry {
    print(convert_list_to_dict('hello'));
    print(convert_list_to_dict('Racecar'));
    print(convert_list_to_dict('abcabc'));
}
