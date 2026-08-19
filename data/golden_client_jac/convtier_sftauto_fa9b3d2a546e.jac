def remove_duplicates(arr: Any) -> object {
    unique_set = `set();
    modified_arr = [];
    for element in arr {
        if (element not in unique_set) {
            unique_set.add(element);
            modified_arr.append(element);
        }
    }
    return modified_arr;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
