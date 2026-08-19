def find_indices(lst: Any) -> object {
    max_val = lst[0];
    indices = [];
    for i in range(len(lst)) {
        if (lst[i] > max_val) {
            max_val = lst[i];
            indices = [];
        }
        if (lst[i] == max_val) {
            indices.append(i);
        }
    }
    return indices;
}



with entry {
    print(find_indices('hello'));
    print(find_indices('Racecar'));
    print(find_indices('abcabc'));
}
