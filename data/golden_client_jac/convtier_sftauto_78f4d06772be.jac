def flatten_and_sort(arr: Any) -> object {
    flattened = [];
    for sublist in arr {
        for element in sublist {
            flattened.append(element);
        }
    }
    unique_elements = `set(flattened);
    sorted_array = sorted(unique_elements);
    return sorted_array;
}



with entry {
    print(flatten_and_sort('hello'));
    print(flatten_and_sort('Racecar'));
    print(flatten_and_sort('abcabc'));
}
