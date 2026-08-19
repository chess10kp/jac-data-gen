def sum_odd_elements(matrix: Any) -> object {
    total = 0;
    for row in matrix {
        for element in row {
            if ((element % 2) != 0) {
                total += element;
            }
        }
    }
    return total;
}



with entry {
    print(sum_odd_elements([]));
}
