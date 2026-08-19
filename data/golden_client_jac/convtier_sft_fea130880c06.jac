def gcd(a: int, b: int) -> int {
    while b != 0 { (a, b) = (b, a % b); }
    return a;
}

with entry {
    print(gcd(48, 18));
}
