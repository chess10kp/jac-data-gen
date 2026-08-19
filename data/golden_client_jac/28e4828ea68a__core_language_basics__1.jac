def divide(a: int, b: int) -> int { return a // b; }

with entry {
    try {
        result = divide(10, 0);
    } except ValueError as e {
        print(f"Error: {e}");
    } finally {
        print("Done");
    }
}
