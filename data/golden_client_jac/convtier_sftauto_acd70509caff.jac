def remove_duplicates_sort(arr: Any) -> object {
    arr = `list(`set(arr));
    arr.sort();
    return arr;
}



with entry {
    print(remove_duplicates_sort('hello'));
    print(remove_duplicates_sort('Racecar'));
    print(remove_duplicates_sort('abcabc'));
}
