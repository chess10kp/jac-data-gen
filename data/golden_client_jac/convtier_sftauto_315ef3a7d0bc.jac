def transpose(matrix: Any) -> object {
    n = len(matrix);
    m = len(matrix[0]);
    transposed = [([0] * n) for _ in range(m)];
    for i in range(n) {
        for j in range(m) {
            transposed[j][i] = matrix[i][j];
        }
    }
    return transposed;
}



with entry {
    print(transpose('hello'));
    print(transpose('Racecar'));
    print(transpose('abcabc'));
}
