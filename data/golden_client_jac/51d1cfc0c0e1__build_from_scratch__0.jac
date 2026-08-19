def base3(n: int) -> str {
    s = "";
    while n > 0 {
        s = str(n % 3) + s;
        n = n // 3;
    }
    return s;
}
