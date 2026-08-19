def complex_calculation(x: int, y: int) -> int {
    return (x * 2 + y) ** 2;
}

with entry {
    answer = complex_calculation(5, 3);
    print(answer);
}
