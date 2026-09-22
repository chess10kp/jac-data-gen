"""base=2: [False, False, False, False, False, False, False, True] -> 128"""
def val_to_dec(value: list[bool], base: int = 2) -> int {
    res = 0;
    for (idx, val) in enumerate(value) {
        res += int(val) * (base ** idx);
    }
    return res;
}