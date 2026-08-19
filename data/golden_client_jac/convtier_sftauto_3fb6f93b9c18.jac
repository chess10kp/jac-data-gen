def transpose_matrix(matrix: Any) -> object {
    transpose = [];
    for i in range(len(matrix)) {
        row = [];
        for j in range(len(matrix)) {
            row.append(matrix[j][i]);
        }
        transpose.append(row);
    }
    return transpose;
}



with entry {
    print(transpose_matrix([]));
    print(transpose_matrix(['a']));
}
