"""Parse passed text string input to integer; return None if non-digit characters."""
def int_input(input_str: str) -> int | None {
    try {
        return int(input_str);
    } except ValueError {
        return None;
    }
}