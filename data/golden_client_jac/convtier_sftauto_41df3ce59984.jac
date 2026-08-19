def sum_array(arr: Any) -> object {
    if (len(arr) == 0) {
        return 0;
    } else {
        return (arr[0] + sum_array(arr[1:]));
    }
}



with entry {
    print(sum_array([]));
}
