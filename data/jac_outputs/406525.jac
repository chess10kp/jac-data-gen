"""Return the number of integers in [a..b] divisible by k."""
def solution(a: int, b: int, k: int) -> int {
    count = (b - a + 1) // k;
    if b % k == 0 {
        count += 1;
    }
    return count;
}