def to_binary(n: int) -> str {
    if n == 0 { return "0"; }
    bits = "";
    while n > 0 {
        bits = str(n % 2) + bits;
        n //= 2;
    }
    return bits;
}

with entry {
    print(to_binary(10));
}
