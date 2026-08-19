def sum_2d_array(arr: Any) -> object {
    if (arr is None) {
        return 0;
    }
    rows = len(arr);
    if (rows == 0) {
        return 0;
    }
    cols = len(arr[0]);
    if (cols == 0) {
        return 0;
    }
    return sum_2d_array_recursive(arr, rows, cols, 0, 0);
}



with entry {
    print(sum_2d_array([]));
}
