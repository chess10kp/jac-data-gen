def split_list_items(lst: Any) -> object {
    return {item[0]: item[1:] for item in lst};
}



with entry {
    print(split_list_items('hello'));
    print(split_list_items('Racecar'));
    print(split_list_items('abcabc'));
}
