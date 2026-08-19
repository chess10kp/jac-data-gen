def safe_divide(a: int, b: int) -> str {
    try {
        result = a // b;
        return f"{a} / {b} = {result}";
    } except ZeroDivisionError {
        return "Error: division by zero";
    }
}
