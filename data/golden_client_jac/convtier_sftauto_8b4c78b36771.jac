def calculate_median(array: Any) -> object {
    sorted_array = sorted(array);
    length = len(sorted_array);
    if ((length % 2) == 1) {
        return sorted_array[(length // 2)];
    } else {
        mid1 = sorted_array[(length // 2)];
        mid2 = sorted_array[((length // 2) - 1)];
        return ((mid1 + mid2) / 2);
    }
}



with entry {
    print(calculate_median('hello'));
    print(calculate_median('Racecar'));
    print(calculate_median('Hello, World!'));
}
