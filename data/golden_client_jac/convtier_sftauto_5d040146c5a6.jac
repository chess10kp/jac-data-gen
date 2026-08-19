def sum_of_each_row(arr: Any) -> object {
    row_sums = [];
    for row in arr {
        row_sum = 0;
        for num in row {
            row_sum += num;
        }
        row_sums.append(row_sum);
    }
    return row_sums;
}



with entry {
    print(sum_of_each_row([]));
}
