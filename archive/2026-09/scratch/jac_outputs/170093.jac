"""Takes a choices tuple and a string and returns the numeric representation."""
def _string_to_numeric(choices: tuple[tuple[int, str], ...], val: str) -> int | None {
    for choice in choices {
        if choice[1] == val {
            return choice[0];
        }
    }
    return None;
}