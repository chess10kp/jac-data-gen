def gcd(a: int, b: int) -> int {
    while b != 0 {
        t = b;
        b = a % b;
        a = t;
    }
    return abs(a);
}

with entry {
    print(gcd(48, 36));
    print(gcd(17, 5));
    print(gcd(100, 75));
    print(gcd(0, 9));
    print(gcd(42, 56));
}
