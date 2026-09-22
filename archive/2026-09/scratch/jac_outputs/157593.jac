"""Round value to next power of 2 value - max 16"""
def _round_pow_2(value: int) -> int {
    if value > 8 {
        return 16;
    } elif value > 4 {
        return 8;
    } elif value > 2 {
        return 4;
    }
    return value;
}