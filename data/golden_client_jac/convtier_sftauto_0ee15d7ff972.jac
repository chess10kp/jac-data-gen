def square(num: Any) -> object {
    bit_length = num.bit_length();
    if ((bit_length % 2) == 0) {
        return (1 << (bit_length // 2));
    } else {
        return (1 << (((bit_length + 1) // 2) - 1));
    }
}



with entry {
    print(square(5));
    print(square(10));
    print(square(0));
}
