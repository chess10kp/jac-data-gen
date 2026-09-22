"""Sum the digits of N."""
def sum_digits(n: Any) -> object {
    L = [];
    for s in str(n) {
        L.append(int(s));
    }
    return sum(L);
}