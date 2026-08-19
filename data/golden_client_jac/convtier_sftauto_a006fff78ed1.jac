def sort_and_unique_copy(arr: Any) -> object {
    sorted_arr = sorted(`set(arr));
    return sorted_arr;
}



with entry {
    print(sort_and_unique_copy('hello'));
    print(sort_and_unique_copy('Racecar'));
    print(sort_and_unique_copy('abcabc'));
}
