def gcd(a: int, b: int) -> int {
    while b != 0 {
        t = b;
        b = a % b;
        a = t;
    }
    return a;
}
