"""Solve an individual problem."""
def solve(N: int) -> int {
    if N == 0 {
        return 0;
    } elif N <= 4 {
        return 1;
    } else {
        return (N - 4) // 2 + 1 + (N % 2);
    }
}