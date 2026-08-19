def row_sums(arr: Any) -> object {
    row_sums = [];
    for row in arr {
        row_sum = sum(row);
        row_sums.append(row_sum);
    }
    return row_sums;
}



with entry {
    print(row_sums([]));
}
