def countBits(n: int) -> list[int] {
    res = [0];
    for i in range(1, n + 1) {
        res.append(res[i & (i - 1)] + 1);
    }
    return res;
}