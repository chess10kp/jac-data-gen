def remove_duplicates(original_list: Any) -> object {
    unique_list = [];
    for element in original_list {
        if (element not in unique_list) {
            unique_list.append(element);
        }
    }
    return unique_list;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
