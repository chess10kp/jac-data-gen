def is_even(num: int) -> bool {
    return num % 2 == 0;
}

with entry {
    print(is_even(4));   # True
    print(is_even(7));   # False
}
