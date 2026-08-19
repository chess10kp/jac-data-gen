def find_equilibrium_indexes(arr: Any) -> object {
    equilibrium_indexes = [];
    for i in range(len(arr)) {
        left_sum = sum(arr[:i]);
        right_sum = sum(arr[(i + 1):]);
        if (left_sum == right_sum) {
            equilibrium_indexes.append(i);
        }
    }
    return equilibrium_indexes;
}



with entry {
    print(find_equilibrium_indexes([]));
}
