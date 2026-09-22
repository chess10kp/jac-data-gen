"""Helper that checks if input is valid."""
def is_input_valid(char: str | None) -> bool {
    if char is None {
        return False;
    }
    if char == "\0" {
        return False;
    }
    return True;
}