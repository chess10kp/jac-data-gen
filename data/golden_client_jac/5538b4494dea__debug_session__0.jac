def complex_calculation(x: int, y: int) -> int {
    result = x * 2;          # <- Set breakpoint here
    result = result + y;
    result = result ** 2;
    return result;
}

with entry {
    answer = complex_calculation(5, 3);
    print(answer);
}
