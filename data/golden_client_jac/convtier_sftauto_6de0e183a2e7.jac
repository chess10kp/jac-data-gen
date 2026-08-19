def calculate_parity(number: Any) -> object {
    if (number < 0) {
        return -1;
    }
    number ^= number >> 32;
    number ^= number >> 16;
    number ^= number >> 8;
    number ^= number >> 4;
    number ^= number >> 2;
    number ^= number >> 1;
    return (number & 1);
}



with entry {
    print(calculate_parity(5));
    print(calculate_parity(2));
}
