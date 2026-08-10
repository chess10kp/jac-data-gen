"""N is length of arr
"""
def searchsorted(arr: list[int], x: int, N: int = -1) -> tuple[int, bool] {
    if N == -1 {
        N = len(arr);
    }
    L = 0;
    R = N - 1;
    done = False;
    eq = False;
    m = (L + R) // 2;
    while not done {
        xm = arr[m];
        if xm < x {
            L = m + 1;
        } elif xm > x {
            R = m - 1;
        } elif xm == x {
            L = m;
            eq = True;
            done = True;
        }
        m = (L + R) // 2;
        if L > R {
            done = True;
        }
    }
    return (L, eq);
}