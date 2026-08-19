def convert(F: Any) -> object {
    C = ((F - 32) << 1) // 9;
    if (C & 1) {
        C += 1;
    }
    return C;
}



with entry {
    print(convert(5));
    print(convert(10));
    print(convert(0));
}
