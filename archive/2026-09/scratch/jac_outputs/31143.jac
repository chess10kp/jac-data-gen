"""
    Rotate a copy of given 2D list
    clockwise by 90 degrees
    and return a new list.

    :param arr: A 2D-list of arbitrary
    dimensions.

    :return: A list that is "arr" rotated
    90 degree clockwise by its center.
    """
def rotate_right(arr: Any) -> object {
    n = len(arr);
    m = len(arr[0]);
    res = [[None for _ in range(n)] for _ in range(m)];
    for i in range(m) {
        for j in range(n) {
            res[i][j] = arr[(n - j - 1)][i];
        }
    }
    return res;
}