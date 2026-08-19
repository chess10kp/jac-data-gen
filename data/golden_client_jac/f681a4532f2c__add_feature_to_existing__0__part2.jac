def example() -> int {
    flags = 0b1010;
    FLAG_MASK = 0b0010;
    NEW_FLAG = 0b0100;
    value = 16;

    has_flag = (flags & FLAG_MASK) != 0;
    flags = flags | NEW_FLAG;
    flags = flags ^ FLAG_MASK;
    inverted = ~value;
    doubled = value << 1;
    quadrupled = value << 2;
    halved = value >> 1;
    quartered = value >> 2;

    # New: count how many bits are set in flags
    bits_set = 0;
    temp = flags;
    while temp > 0 {
        bits_set += temp & 1;
        temp = temp >> 1;
    }
    return bits_set;
}

with entry {
    print(example());
}
