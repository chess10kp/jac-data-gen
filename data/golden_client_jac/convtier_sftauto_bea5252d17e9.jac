def is_power_of_two(n: Any) -> object {
    return ((n > 0) and ((n & (n - 1)) == 0));
}



with entry {
    print(is_power_of_two(5));
    print(is_power_of_two(2));
}
