def double_up(str_list: Any) -> object {
    double_list = [];
    for string in str_list {
        double_str = string + string;
        strlen = len(string);
        char_at_index = double_str[strlen];
        if char_at_index.islower() {
            char_at_index = char_at_index.upper();
        }
        double_list.append(double_str);
        double_list.append(char_at_index);
    }
    return double_list;
}



with entry {
    print(double_up('hello'));
    print(double_up('Racecar'));
    print(double_up('abcabc'));
}
