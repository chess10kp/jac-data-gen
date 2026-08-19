def remove_duplicates_and_sort(lst: Any) -> object {
    unique_lst = `list(`set(lst));
    unique_lst.sort();
    return unique_lst;
}



with entry {
    print(remove_duplicates_and_sort('hello'));
    print(remove_duplicates_and_sort('Racecar'));
    print(remove_duplicates_and_sort('abcabc'));
}
