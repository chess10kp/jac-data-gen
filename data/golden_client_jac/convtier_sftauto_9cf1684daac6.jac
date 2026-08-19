def column_sum(arr: Any) -> object {
    if not arr {
        return [];
    }
    rows = len(arr);
    cols = len(arr[0]);
    result = [0] * cols;
    for col in range(cols) {
        for row in range(rows) {
            result[col] += arr[row][col];
        }
    }
    return result;
}



with entry {
    print(column_sum(0));
}
