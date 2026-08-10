"""Binary search for value in a row-major sorted matrix."""
def searching_in_a_matrix(m1: list[list[int]], value: int) -> bool {
    rows = len(m1);
    cols = len(m1[0]);
    lo = 0;
    hi = rows * cols;
    while lo < hi {
        mid = (lo + hi) // 2;
        row = mid // cols;
        col = mid % cols;
        v = m1[row][col];
        if v == value {
            return True;
        } elif v > value {
            hi = mid;
        } else {
            lo = mid + 1;
        }
    }
    return False;
}