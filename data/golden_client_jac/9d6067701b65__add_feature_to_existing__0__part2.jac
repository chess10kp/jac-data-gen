def compute(x: int) -> int {
    return x * x;
}

with entry {
    x = 5;
    print(x);
    result = compute(x) + 10;
    print(result);
}
