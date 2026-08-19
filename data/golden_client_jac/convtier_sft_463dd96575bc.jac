def calculate_factorial(n: int) -> int {
    if n == 0 { return 1; }
    return n * calculate_factorial(n - 1);
}

with entry {
    print(calculate_factorial(6));
}
