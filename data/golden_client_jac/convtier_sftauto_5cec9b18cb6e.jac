def convert_to_dictionary(lst: Any) -> object {
    if (len(lst) == 0) {
        return {};
    }
    unique_lst = [];
    lengths = {};
    for string in lst {
        if (string not in unique_lst) {
            unique_lst.append(string);
            lengths[string] = len(string);
        }
    }
    return lengths;
}



with entry {
    print(convert_to_dictionary('hello'));
    print(convert_to_dictionary('Racecar'));
    print(convert_to_dictionary('abcabc'));
}
