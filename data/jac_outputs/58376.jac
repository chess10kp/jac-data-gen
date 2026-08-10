"""Return power of 2 for highest bit set for integer"""
def maxBit(int_val: int) -> int {
    length = 0;
    count = 0;
    while int_val {
        count += int_val & 1;
        length += 1;
        int_val >>= 1;
    }
    return length - 1;
}