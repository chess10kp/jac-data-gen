def sum_matrix(matrix: Any) -> object {
    row_sums = [];
    for row in matrix {
        row_sum = sum(row);
        row_sums.append(row_sum);
    }
    return sum(row_sums);
}



with entry {
    print(sum_matrix([]));
}
