def find_indices(array: Any) -> object {
    indices = [];
    for i in range(len(array)) {
        if ((array[i] % 2) == 0) {
            indices.append(i);
        }
    }
    return indices[::-1];
}



with entry {
    print(find_indices([]));
}
