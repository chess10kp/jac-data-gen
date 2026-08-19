# Check if nth bit is set
def is_bit_set(value: int, n: int) -> bool {
    return (value & (1 << n)) != 0;
}

# Set nth bit
def set_bit(value: int, n: int) -> int {
    return value | (1 << n);
}

# Clear nth bit
def clear_bit(value: int, n: int) -> int {
    return value & ~(1 << n);
}

# Toggle nth bit
def toggle_bit(value: int, n: int) -> int {
    return value ^ (1 << n);
}

# Check if power of 2
def is_power_of_two(n: int) -> bool {
    return n > 0 and (n & (n - 1)) == 0;
}
