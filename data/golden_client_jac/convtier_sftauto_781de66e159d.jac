def calculate_transpose(matrix: Any) -> object {
    m = len(matrix);
    n = len(matrix[0]);
    transpose = [[0 for _ in range(m)] for _ in range(n)];
    for i in range(m) {
        for j in range(n) {
            transpose[j][i] = matrix[i][j];
        }
    }
    return transpose;
}



with entry {
    print(calculate_transpose('hello'));
    print(calculate_transpose('Racecar'));
    print(calculate_transpose('abcabc'));
}
