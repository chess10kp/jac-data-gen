def divide(a: float, b: float) -> float {
    if b == 0 {
        raise ValueError("Cannot divide by zero");
    }
    return a / b;
}

with entry {
    try {
        result = divide(10, 0);
    } except ValueError as e {
        print(f"Error: {e}");
    } finally {
        print("Done");
    }
}
