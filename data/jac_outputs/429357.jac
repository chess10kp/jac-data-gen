"""Computes the Levenshtein and restricted Damerau-Levenshtein distances between two Unicode strings using the Wagner-Fischer algorithm."""
def _levenshtein_compute(source: str, target: str, rd_flag: bool) -> int {
    s_range = range(len(source) + 1);
    t_range = range(len(target) + 1);
    matrix = [[i if j == 0 else j for j in t_range] for i in s_range];
    for i in s_range[1:] {
        for j in t_range[1:] {
            del_dist = matrix[i - 1][j] + 1;
            ins_dist = matrix[i][j - 1] + 1;
            sub_trans_cost = 0 if source[i - 1] == target[j - 1] else 1;
            sub_dist = matrix[i - 1][j - 1] + sub_trans_cost;
            matrix[i][j] = min(del_dist, ins_dist, sub_dist);
            if rd_flag and i > 1 and j > 1 and source[i - 1] == target[j - 2] and source[i - 2] == target[j - 1] {
                trans_dist = matrix[i - 2][j - 2] + sub_trans_cost;
                matrix[i][j] = min(matrix[i][j], trans_dist);
            }
        }
    }
    return matrix[len(source)][len(target)];
}