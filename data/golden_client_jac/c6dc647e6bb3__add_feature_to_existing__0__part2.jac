def example() -> float {
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

    count += 1;
    total *= tax_rate;
    value **= 2;

    flags |= NEW_FLAG;
    flags &= ~OLD_FLAG;
    bits ^= mask;
    register <<= 4;

    # New: floor-divide and modulo augmented assignment
    total //= 2;
    register %= 5;

    return total;
}

with entry {
    print(example());
}
