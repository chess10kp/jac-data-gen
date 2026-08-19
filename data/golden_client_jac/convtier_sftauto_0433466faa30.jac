def transpose_array(arr: Any) -> object {
    rows = len(arr);
    cols = len(arr[0]);
    transposed_arr = [[0 for _ in range(rows)] for _ in range(cols)];
    for i in range(rows) {
        for j in range(cols) {
            transposed_arr[j][i] = arr[i][j];
        }
    }
    return transposed_arr;
}



with entry {
    print(transpose_array('hello'));
    print(transpose_array('Racecar'));
    print(transpose_array('abcabc'));
}
