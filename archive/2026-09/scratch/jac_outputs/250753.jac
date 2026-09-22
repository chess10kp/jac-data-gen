"""A simple linear system of equations."""
def linear_system_example(x: list[int]) -> list[int] {
    n = len(x);
    res = [0] * n;
    for i in range(n) {
        for j in range(n) {
            res[i] += (1 + i * j) * x[j];
        }
    }
    return res;
}