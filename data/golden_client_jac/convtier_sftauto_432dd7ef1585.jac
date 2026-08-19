def reverse_matrix(matrix: Any) -> object {
    num_rows = len(matrix);
    num_cols = len(matrix[0]);
    reversed_matrix = [([None] * num_rows) for _ in range(num_cols)];
    for i in range(num_rows) {
        for j in range(num_cols) {
            reversed_matrix[j][i] = matrix[i][j];
        }
    }
    return reversed_matrix;
}



with entry {
    print(reverse_matrix('hello'));
    print(reverse_matrix('Racecar'));
    print(reverse_matrix('abcabc'));
}
