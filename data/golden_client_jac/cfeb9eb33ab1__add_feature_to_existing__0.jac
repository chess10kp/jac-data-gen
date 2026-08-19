def count_bits(value: int) -> int {
    count = 0;
    while value > 0 {
        count += value % 2;
        value = value / 2;
    }
    return count;
}
