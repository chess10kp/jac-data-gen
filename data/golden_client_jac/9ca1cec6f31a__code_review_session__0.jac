def validate(value: str) {
    if not value {
        raise ValueError("Invalid input");
    }
}
def process(item: str) {
    try {
        validate(item);
    } except ValueError as e {
        raise RuntimeError(f"Failed to process: {item}") from e;
    }
}
