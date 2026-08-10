"""Compare 2 keys."""
def _cmp(kd1: str, kd2: str) -> int {
    if kd1 == kd2 {
        return 0;
    }
    if kd1 < kd2 {
        return -1;
    }
    return 1;
}