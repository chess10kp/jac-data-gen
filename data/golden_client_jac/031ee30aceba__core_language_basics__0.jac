def add(x: int, y: int) -> int {
    return x + y;
}

with entry {
    result = add(5, 3);
    print(result);  # Shows: 8

    # Use directly in calculations
    total = add(10, 20) + add(5, 5);
    print(total);  # Shows: 40
}
