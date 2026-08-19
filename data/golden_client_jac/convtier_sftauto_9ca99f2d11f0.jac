def calculate_sum(row: Any) -> object {
    sorted_row = sorted(`set(row));
    row_sum = 0;
    for element in sorted_row {
        row_sum += element;
    }
    return round(row_sum);
}



with entry {
    print(calculate_sum([81]));
    print(calculate_sum([]));
    print(calculate_sum([100]));
}
