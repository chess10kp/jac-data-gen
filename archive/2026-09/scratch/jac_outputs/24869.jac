"""N is length of arr."""
def searchsorted(arr: list[int], N: int, x: int) -> int {
    L = 0;
    R = N - 1;
    done = False;
    m = (L + R) // 2;
    while not done {
        if arr[m] < x {
            L = m + 1;
        } elif arr[m] > x {
            R = m - 1;
        } elif arr[m] == x {
            done = True;
        }
        m = (L + R) // 2;
        if L > R {
            done = True;
        }
    }
    return L;
}