def risky_operation() -> int {
    raise ValueError("error");
}

def example() {
    try {
        result = risky_operation();
    } except ValueError {
        print("Value error occurred");
    }
}
