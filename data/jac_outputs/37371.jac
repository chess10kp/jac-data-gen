"""Calculate q^-1 mod p."""
def inv(q: int, p: int) -> int | None {
    for i in range(p) {
        if q * i % p == 1 {
            return i;
        }
    }
}