def retrieve_unique_descending(lst: List[int]) -> List[int] {
    unique_values = `set(lst);
    unique_values_list = `list(unique_values);
    unique_values_list.sort(reverse=True);
    return unique_values_list;
}



with entry {
    print(retrieve_unique_descending('hello'));
    print(retrieve_unique_descending('Racecar'));
    print(retrieve_unique_descending('abcabc'));
}
