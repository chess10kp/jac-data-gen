def example() {
    count = 0;
    total = 100.0;
    tax_rate = 1.08;
    value = 2;
    flags = 0b0000;
    NEW_FLAG = 0b0100;
    OLD_FLAG = 0b0010;
    bits = 0b1010;
    mask = 0b0011;
    register = 1;

    # Numeric augmented assignment
    count += 1;
    total *= tax_rate;
    value **= 2;

    # Bitwise augmented assignment
    flags |= NEW_FLAG;      # Set a flag
    flags &= ~OLD_FLAG;     # Clear a flag
    bits ^= mask;           # Toggle bits
    register <<= 4;         # Shift left
}
