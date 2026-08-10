"""Write a function to compute the fibonacci sequence value to the requested iteration."""
def solution(number: int) -> int {
    m = {0: 0, 1: 1};
    for i in range(2, number + 1) {
        m[i] = m[i - 1] + m[i - 2];
    }
    return m[number];
}