def find_row_sums(matrix: Any) -> object {
    row_sums = [];
    for row in matrix {
        if `any((num < 0) for num in row) {
            continue;
        }
        row_sums.append(sum(row));
    }
    return row_sums;
}



with entry {
    print(find_row_sums([]));
}
