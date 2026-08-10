"""Returns a number s for which s^3 ends with the provided suffix."""
def attack(suffix_bits: int, suffix: int) -> int {
    assert suffix % 2 == 1, "Target suffix must be odd";
    s = 1;
    for i in range(suffix_bits) {
        if ((s ** 3) >> i) & 1 != (suffix >> i) & 1 {
            s |= 1 << i;
        }
    }
    return s;
}