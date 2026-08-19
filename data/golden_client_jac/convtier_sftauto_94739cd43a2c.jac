def flatten_and_sort(arr: Any) -> object {
    flattened = [item for sublist in arr for item in sublist];
    unique = `list(`set(flattened));
    unique.sort();
    return unique;
}



with entry {
    print(flatten_and_sort('hello'));
    print(flatten_and_sort('Racecar'));
    print(flatten_and_sort('abcabc'));
}
