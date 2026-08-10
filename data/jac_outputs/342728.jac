"""
    Returns all possible subsets of the set (0, 1, ..., n-1) except the
    empty set, listed in reversed lexicographical order according to binary
    representation, so that the case of the fourth root is treated last.
    """
def subsets(n: int) -> list[list[int]] {
    if n == 1 {
        a = [[1]];
    } elif n == 2 {
        a = [[1, 0], [0, 1], [1, 1]];
    } elif n == 3 {
        a = [
            [1, 0, 0],
            [0, 1, 0],
            [1, 1, 0],
            [0, 0, 1],
            [1, 0, 1],
            [0, 1, 1],
            [1, 1, 1]
        ];
    } else {
        b = subsets(n - 1);
        a0 = [x + [0] for x in b];
        a1 = [x + [1] for x in b];
        a = a0 + [[0] * (n - 1) + [1]] + a1;
    }
    return a;
}