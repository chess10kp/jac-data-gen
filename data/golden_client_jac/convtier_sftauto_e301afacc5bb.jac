def multiplication_table(number: Any) -> object {
    if (not isinstance(number, int) or (number <= 0)) {
        raise ValueError("Input must be a positive integer");
    }
    table = [];
    for row in range(1, (number + 1)) {
        row_list = [];
        for column in range(1, (number + 1)) {
            row_list.append((row * column));
        }
        table.append(row_list);
    }
    return table;
}



with entry {
    print(multiplication_table(5));
    print(multiplication_table(10));
    print(multiplication_table(2));
}
