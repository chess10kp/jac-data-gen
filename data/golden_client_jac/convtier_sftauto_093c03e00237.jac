def multiplication_table(n: Any) -> object {
    table = [];
    for i in range(1, 13) {
        row = [];
        for j in range(1, (n + 1)) {
            row.append((i * j));
        }
        table.append(row);
    }
    return table;
}



with entry {
    print(multiplication_table(5));
    print(multiplication_table(10));
    print(multiplication_table(2));
}
