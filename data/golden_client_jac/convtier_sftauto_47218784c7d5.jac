def get_row_sums(matrix: Any) -> object {
    row_sums = [];
    for row in matrix {
        row_sum = sum(row);
        if ((row_sum >= 50) and (row_sum <= 1000)) {
            row_sums.append(row_sum);
        }
    }
    return row_sums;
}



with entry {
    print(get_row_sums([]));
}
