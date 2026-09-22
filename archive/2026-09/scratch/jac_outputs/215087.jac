"""
        Return the minimum number of character deletions,
        insertions and/or substitutions between two strings.
    """
def levenshtein_distance(str1: str, str2: str) -> int {
    (cols, rows) = (len(str1), len(str2));
    matrix = [[0 for col in range(cols + 1)] for row in range(rows + 1)];
    for col in range(1, cols + 1) {
        matrix[0][col] = col;
    }
    for row in range(1, rows + 1) {
        matrix[row][0] = row;
    }
    for row in range(1, rows + 1) {
        for col in range(1, cols + 1) {
            cost = 0 if str1[col - 1] == str2[row - 1] else 1;
            matrix[row][col] = min(
                matrix[row][col - 1] + 1,
                matrix[row - 1][col] + 1,
                matrix[row - 1][col - 1] + cost
            );
        }
    }
    return matrix[rows][cols];
}