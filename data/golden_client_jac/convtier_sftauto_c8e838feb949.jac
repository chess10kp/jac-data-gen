def remove_duplicates(input_list: Any) -> object {
    unique_list = [];
    for item in input_list {
        if (item not in unique_list) {
            unique_list.append(item);
        }
    }
    return unique_list;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
