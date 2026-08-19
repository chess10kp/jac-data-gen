def remove_duplicates_and_sort(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    }
    unique_arr = `list(`set(arr));
    unique_arr.sort(reverse=True);
    return unique_arr;
}



with entry {
    print(remove_duplicates_and_sort('hello'));
    print(remove_duplicates_and_sort('Racecar'));
    print(remove_duplicates_and_sort('abcabc'));
}
