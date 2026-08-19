def calculate_bits(n: Any) -> object {
    count = 0;
    while (n > 0) {
        count += 1;
        n = n // 2;
    }
    return count;
}



with entry {
    print(calculate_bits(5));
    print(calculate_bits(10));
    print(calculate_bits(2));
}
