"""Multiply square matrices of same dimension M and N"""
def mult_matrix(M: Any, N: Any) -> object {
    tuple_N = zip(*N);
    return [
        [sum((el_m * el_n) for (el_m, el_n) in zip(row_m, col_n)) for col_n in tuple_N]
        for row_m in M
    ];
}