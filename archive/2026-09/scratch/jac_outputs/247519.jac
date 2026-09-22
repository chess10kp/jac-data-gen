"""Checks if a matrix is symmetrical"""
def is_symmetrical(matrix: list[str]) -> bool {
    result = True;
    for i in range(8) {
        row = matrix[i * 8:(i + 1) * 8];
        result = result and row[0:3] == row[4:];
    }
    return result;
}