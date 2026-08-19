def divide(a: int, b: int) -> int { return a // b; }

with entry {
    try {
        result = divide(10, 0);
        print(result);
    } except ZeroDivisionError as e {
        print(f"Cannot divide by zero: {e}");
    } except ValueError as e {
        print(f"Error: {e}");
    } finally {
        print("Done");
    }
}
