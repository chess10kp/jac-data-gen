def sum_array_elements(arr: Any) -> object {
    if (len(arr) == 0) {
        return 0;
    }
    return (arr[0] + sum_array_elements(arr[1:]));
}



with entry {
    print(sum_array_elements([]));
}
