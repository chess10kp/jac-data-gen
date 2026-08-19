def remove_duplicates_and_sort(lst: Any) -> object {
    unique_dict = {};
    for num in lst {
        unique_dict[num] = True;
    }
    unique_list = `list(unique_dict.keys());
    unique_list.sort();
    return unique_list;
}



with entry {
    print(remove_duplicates_and_sort('hello'));
    print(remove_duplicates_and_sort('Racecar'));
    print(remove_duplicates_and_sort('abcabc'));
}
