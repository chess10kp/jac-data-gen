def find_indices(array: Any) -> object {
    indices = {};
    for i in range(len(array)) {
        if (array[i] not in indices) {
            indices[array[i]] = i;
        }
    }
    return sorted(indices.values());
}



with entry {
    print(find_indices('hello'));
    print(find_indices('Racecar'));
    print(find_indices('abcabc'));
}
