def row_sums(matrix: Any) -> object {
    result = [0] * (len(matrix) + 1);
    for i in range(len(matrix)) {
        row_sum = sum(matrix[i]);
        result[i] = row_sum;
        result[-1] += row_sum;
    }
    return result;
}



with entry {
    print(row_sums([]));
}
