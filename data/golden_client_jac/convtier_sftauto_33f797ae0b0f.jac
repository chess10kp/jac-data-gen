def minimum_rope_cut(length: Any) -> object {
    segments = length // 10;
    remainder = length % 10;
    if (remainder <= 5) {
        return remainder;
    } else {
        return (10 - remainder);
    }
}



with entry {
    print(minimum_rope_cut(5));
    print(minimum_rope_cut(10));
    print(minimum_rope_cut(2));
}
