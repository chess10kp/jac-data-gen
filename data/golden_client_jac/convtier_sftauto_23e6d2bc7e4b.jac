def transpose_array(arr: Any) -> object {
    transposed_array = [];
    for col in range(len(arr[0])) {
        transposed_row = [];
        for row in range(len(arr)) {
            transposed_row.append(arr[row][col]);
        }
        transposed_array.append(transposed_row);
    }
    return transposed_array;
}



with entry {
    print(transpose_array('hello'));
    print(transpose_array('Racecar'));
    print(transpose_array('abcabc'));
}
