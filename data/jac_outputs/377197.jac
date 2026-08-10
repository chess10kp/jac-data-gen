"""find pick element"""
def find_peak(A: list[int]) -> int | None {
    if A == [] {
        return None;
    }
    def recursive(A: list[int], left: int = 0, right: int = len(A) - 1) -> int {
        mid = (left + right) // 2;
        if (mid == 0 or A[mid - 1] <= A[mid]) and (mid == len(A) - 1 or A[mid + 1] <= A[mid]) {
            return A[mid];
        }
        if mid - 1 >= 0 and A[mid - 1] > A[mid] {
            return recursive(A, left, mid - 1);
        }
        return recursive(A, mid + 1, right);
    }
    return recursive(A);
}