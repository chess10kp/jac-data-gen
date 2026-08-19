def divide(a: float, b: float) -> float {
    if b == 0 {
        raise ValueError("Cannot divide by zero");
    }
    return a / b;
}

def safe_divide(a: float, b: float) -> None {
    try {
        result = divide(a, b);
    } except ValueError as e {
        print(f"Error: {e}");
    } finally {
        print("Done");
    }
}

with entry {
    safe_divide(10, 0);
}
