def sum_of_rows(arr: Any) -> object {
    row_sums = [];
    for row in arr {
        row_sum = sum(row);
        row_sums.append(row_sum);
    }
    return row_sums;
}



with entry {
    print(sum_of_rows([]));
}
