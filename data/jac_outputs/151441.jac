"""finds the closest number in sorted list l to n"""
def closest(l: list[int | float], n: int | float) -> int | float {
    mid = int(len(l) / 2);
    if len(l) < 7 {
        return min(l, key=lambda (e: int | float) { abs(n - e); });
    } elif n > l[mid] {
        return closest(l[mid:], n);
    } else {
        return closest(l[:(mid + 1)], n);
    }
}