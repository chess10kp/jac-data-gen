# sum.na.jac
def compute_sum(n: int) -> int {
    total: int = 0;
    i: int = 1;
    while i <= n {
        total = total + i;
        i = i + 1;
    }
    return total;
}

with entry {
    print(f"Sum of 1 to 10: {compute_sum(10)}");
}
