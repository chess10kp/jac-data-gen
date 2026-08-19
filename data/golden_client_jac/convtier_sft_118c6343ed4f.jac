def is_power_of_two(n: int) -> bool {
    return n > 0 and (n & (n - 1)) == 0;
}

with entry {
    print(is_power_of_two(16));
    print(is_power_of_two(18));
}
