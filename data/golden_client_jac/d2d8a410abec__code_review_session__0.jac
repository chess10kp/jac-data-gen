def safe_divide(a: int, b: int) -> str {
    if b == 0 {
        return "Error: division by zero";
    }
    result = a // b;
    return f"{a} / {b} = {result}";
}

with entry {
    print(safe_divide(10, 3));
    print(safe_divide(10, 0));
}
