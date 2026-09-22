"""Returns the missing number from array A [1...N+1] with len(A) = N."""
def solution(A: list[int]) -> int {
    if len(A) == 0 {
        return 1;
    }
    A.sort();
    ind = 1;
    while A[ind - 1] == ind {
        if ind == len(A) {
            return ind + 1;
        }
        ind += 1;
    }
    return ind;
}