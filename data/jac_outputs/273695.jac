""" divides matrix by input divisor"""
def matrix_divided(matrix: Any, div: Any) -> object {
    if (div == 0) {
        raise ZeroDivisionError('division by zero');
    }
    if not isinstance(div, (int, float)) {
        raise TypeError('div must be a number');
    }
    new = [];
    rowlen = len(matrix[0]);
    for row in matrix {
        sub = [];
        if (len(row) != rowlen) {
            raise TypeError('Each row of the matrix must have the same size');
        }
        for i in range(len(row)) {
            if not isinstance(row[i], (int, float)) {
                raise TypeError(
                    'matrix must be a matrix (list of lists) of ' 'integers/floats'
                );
            }
            sub.append(round((row[i] / div), 2));
        }
        new.append(sub);
    }
    return new;
}