def validate(input: str) -> None {
    if not input {
        # Raise an exception
        raise ValueError("Invalid input");
    }
}

def process(item: str) -> None {
    try {
        validate(item);
    } except ValueError as e {
        # Re-raise with more context
        raise RuntimeError(f"Failed to process: {item}") from e;
    }
}
