def base_2_logarithm(n: Any) -> object {
    count = 0;
    while n {
        n >>= 1;
        count += 1;
    }
    return count;
}



with entry {
    print(base_2_logarithm(5));
    print(base_2_logarithm(10));
    print(base_2_logarithm(2));
}
