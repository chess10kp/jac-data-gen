def row_sums(arr: Any) -> object {
    sums = [];
    for row in arr {
        row_sum = 0;
        for num in row {
            if (num > 0) {
                row_sum += num;
            }
        }
        sums.append(row_sum);
    }
    return sums;
}



with entry {
    print(row_sums([]));
}
