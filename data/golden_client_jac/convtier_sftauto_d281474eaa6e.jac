def transpose(arr: Any) -> object {
    rows = len(arr);
    cols = len(arr[0]);
    transposed_arr = [([0] * rows) for _ in range(cols)];
    for i in range(rows) {
        for j in range(cols) {
            transposed_arr[j][i] = arr[i][j];
        }
    }
    return transposed_arr;
}



with entry {
    print(transpose('hello'));
    print(transpose('Racecar'));
    print(transpose('abcabc'));
}
