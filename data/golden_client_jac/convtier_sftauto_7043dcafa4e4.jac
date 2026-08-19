def find_equilibrium_indexes(arr: Any) -> object {
    equilibrium_indexes = [];
    total_sum = sum(arr);
    left_sum = 0;
    for i in range(len(arr)) {
        total_sum -= arr[i];
        if (left_sum == total_sum) {
            equilibrium_indexes.append(i);
        }
        left_sum += arr[i];
    }
    return equilibrium_indexes;
}



with entry {
    print(find_equilibrium_indexes([2, 9]));
    print(find_equilibrium_indexes([2]));
}
