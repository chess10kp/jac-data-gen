def reverse_matrix(matrix: Any) -> object {
    new_matrix = [];
    for i in range(len(matrix)) {
        new_matrix.append([]);
        for j in range(len(matrix[i])) {
            new_matrix[i].insert(0, matrix[i][j]);
        }
    }
    return new_matrix;
}



with entry {
    print(reverse_matrix('hello'));
    print(reverse_matrix('Racecar'));
    print(reverse_matrix('abcabc'));
}
