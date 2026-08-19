def remove_duplicates(arr: Any) -> object {
    if not isinstance(arr, `list) {
        return arr;
    }
    unique_values = [];
    for item in arr {
        if isinstance(item, `list) {
            item = remove_duplicates(item);
        }
        if (item not in unique_values) {
            unique_values.append(item);
        }
    }
    return unique_values;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
