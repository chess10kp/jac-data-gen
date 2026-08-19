def flatten_and_sort(arr: Any) -> object {
    if not arr {
        return [];
    }
    flattened = [];
    for sublist in arr {
        flattened.extend(sublist);
    }
    flattened = `list(`set(flattened));
    flattened.sort();
    return flattened;
}



with entry {
    print(flatten_and_sort('hello'));
    print(flatten_and_sort('Racecar'));
    print(flatten_and_sort('abcabc'));
}
