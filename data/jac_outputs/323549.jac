def _dec(A: list[int]) -> int {
    total = 0;
    for (i, a) in enumerate(A) {
        total += a * (1 << i);
    }
    return total;
}