def example() {
    flags = 0b1010;
    FLAG_MASK = 0b0010;
    NEW_FLAG = 0b0100;
    value = 16;

    # Bitwise AND - check if bit is set
    has_flag = (flags & FLAG_MASK) != 0;

    # Bitwise OR - set a bit
    flags = flags | NEW_FLAG;

    # Bitwise XOR - toggle a bit
    flags = flags ^ FLAG_MASK;

    # Bitwise NOT - invert all bits
    inverted = ~value;

    # Left shift - multiply by 2^n
    doubled = value << 1;      # value * 2
    quadrupled = value << 2;   # value * 4

    # Right shift - divide by 2^n
    halved = value >> 1;       # value // 2
    quartered = value >> 2;    # value // 4
}
