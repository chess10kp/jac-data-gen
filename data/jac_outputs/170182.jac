"""Return a matrix as a matrix-multiplication of X_M and arbitary number of matrices *Y_M"""
def matrix_multiplication(X_M: list[list[int]], *Y_M: list[list[int]]) -> list[list[int]] {
    def _mat_mult(X_M: list[list[int]], Y_M: list[list[int]]) -> list[list[int]] {
        assert len(X_M[0]) == len(Y_M);
        result = [[0 for i in range(len(Y_M[0]))] for j in range(len(X_M))];
        for i in range(len(X_M)) {
            for j in range(len(Y_M[0])) {
                for k in range(len(Y_M)) {
                    result[i][j] += X_M[i][k] * Y_M[k][j];
                }
            }
        }
        return result;
    }
    result = X_M;
    for Y in Y_M {
        result = _mat_mult(result, Y);
    }
    return result;
}