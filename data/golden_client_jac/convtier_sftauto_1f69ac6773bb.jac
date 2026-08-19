def remove_duplicates_and_sort(string: Any) -> object {
    string = string.lower();
    string = ''.join(`set(string));
    sorted_string = ''.join(sorted(string));
    return sorted_string;
}



with entry {
    print(remove_duplicates_and_sort('hello'));
    print(remove_duplicates_and_sort('Racecar'));
    print(remove_duplicates_and_sort('abcabc'));
}
