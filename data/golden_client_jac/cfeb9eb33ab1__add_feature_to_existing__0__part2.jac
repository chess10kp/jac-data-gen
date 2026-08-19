def is_bit_set(value: int, n: int) -> bool {
    return (value & (1 << n)) != 0;
}

def set_bit(value: int, n: int) -> int {
    return value | (1 << n);
}

def clear_bit(value: int, n: int) -> int {
    return value & ~(1 << n);
}

def toggle_bit(value: int, n: int) -> int {
    return value ^ (1 << n);
}

def is_power_of_two(n: int) -> bool {
    return n > 0 and (n & (n - 1)) == 0;
}

# New: count the number of set bits (population count)
def count_bits(value: int) -> int {
    count = 0;
    while value > 0 {
        count += value & 1;
        value = value >> 1;
    }
    return count;
}

with entry {
    print(count_bits(0b1011));
}
