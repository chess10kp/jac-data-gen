def example() -> int {
    decimal = 42;
    hex_val = 0x2A;
    octal = 0o52;
    binary = 0b101010;
    floating = 3.14159;
    scientific = 1.5e-10;

    million = 1_000_000;
    hex_word = 0xFF_FF;

    # New: verify the different bases all equal 42
    total = decimal + hex_val + octal + binary;
    return total;
}

with entry {
    print(example());
}
