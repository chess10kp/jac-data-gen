def trailing_zeros(n: Any) -> object {
    count = 0;
    i = 5;
    while ((n // i) >= 1) {
        count += n // i;
        i *= 5;
    }
    return count;
}



with entry {
    print(trailing_zeros(5));
    print(trailing_zeros(10));
    print(trailing_zeros(2));
}
