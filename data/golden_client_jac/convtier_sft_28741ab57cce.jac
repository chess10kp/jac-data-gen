def binary_to_int(bits: str) -> int {
    result = 0;
    for ch in bits { result = result * 2 + int(ch); }
    return result;
}

with entry {
    print(binary_to_int("1010"));
}
