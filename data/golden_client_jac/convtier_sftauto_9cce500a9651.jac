def count_ones_zeros(num: Any) -> object {
    if (num < 0) {
        return "Error: Negative numbers are not allowed.";
    }
    binary = bin((num & 65535))[2:].zfill(16);
    ones = binary.count('1');
    zeros = binary.count('0');
    return f"Binary representation: {binary}\nNumber of ones: {ones}\nNumber of zeros: {zeros}";
}



with entry {
    print(count_ones_zeros(5));
    print(count_ones_zeros(10));
    print(count_ones_zeros(2));
}
