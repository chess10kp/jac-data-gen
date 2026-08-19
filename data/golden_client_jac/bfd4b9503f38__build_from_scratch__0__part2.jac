def is_even(n: int) -> bool {
    return n % 2 == 0;
}

with entry {
    for x in [0, 1, 2, 7, -4] {
        print(is_even(x));
    }
}
