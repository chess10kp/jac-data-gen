def find_smallest_index(array: Any) -> object {
    min_index = 0;
    for i in range(1, len(array)) {
        if (array[i] < array[min_index]) {
            min_index = i;
        }
    }
    return min_index;
}



with entry {
    print(find_smallest_index('hello'));
    print(find_smallest_index('Racecar'));
    print(find_smallest_index('Hello, World!'));
}
