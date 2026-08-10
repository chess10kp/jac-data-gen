"""Return the edit distance between two strings."""
def getEditDistance(str1: str, str2: str) -> int {
    if len(str1) == 0 {
        return len(str2);
    }
    if len(str2) == 0 {
        return len(str1);
    }
    matrix = [[i for k in range(len(str2) + 1)] for i in range(len(str1) + 1)];
    for i in range(len(str2) + 1) {
        matrix[0][i] = i;
    }
    for i in range(len(str2)) {
        for j in range(len(str1)) {
            if str2[i] == str1[j] {
                matrix[j + 1][i + 1] = matrix[j][i];
            } else {
                matrix[j + 1][i + 1] = min(
                    matrix[j][i + 1] + 1,
                    matrix[j + 1][i] + 1,
                    matrix[j][i] + 1
                );
            }
        }
    }
    return matrix[-1][-1];
}