def transpose_array(arr: Any) -> object {
    transposed_array = [];
    for column in range(len(arr[0])) {
        transposed_column = [];
        for row in range(len(arr)) {
            transposed_column.append(arr[row][column]);
        }
        transposed_array.append(transposed_column);
    }
    return transposed_array;
}



with entry {
    print(transpose_array('hello'));
    print(transpose_array('Racecar'));
    print(transpose_array('abcabc'));
}
