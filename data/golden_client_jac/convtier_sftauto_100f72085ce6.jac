def calculate_sum(arr: Any) -> object {
    if (len(arr) == 0) {
        return 0;
    } else {
        return (arr[0] + calculate_sum(arr[1:]));
    }
}



with entry {
    print(calculate_sum([]));
}
