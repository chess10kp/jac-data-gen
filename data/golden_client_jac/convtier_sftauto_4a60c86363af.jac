def sum_matrix(matrix: Any) -> object {
    total_sum = 0;
    for row in matrix {
        for element in row {
            if (element >= 0) {
                total_sum += element;
            }
        }
    }
    return total_sum;
}



with entry {
    print(sum_matrix([]));
}
