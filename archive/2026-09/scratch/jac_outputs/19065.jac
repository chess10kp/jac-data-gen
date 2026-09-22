"""Divide-and-conquer search; O(log n)."""
def bisection_search2(L: list[int], e: int) -> bool {
    def helper(L: list[int], e: int, low: int, high: int) -> bool {
        if high == low {
            return L[low] == e;
        }
        mid = (low + high) // 2;
        if L[mid] == e {
            return True;
        } elif L[mid] > e {
            if low == mid {
                return False;
            } else {
                return helper(L, e, low, mid - 1);
            }
        } else {
            return helper(L, e, mid + 1, high);
        }
    }
    if len(L) == 0 {
        return False;
    }
    return helper(L, e, 0, len(L) - 1);
}