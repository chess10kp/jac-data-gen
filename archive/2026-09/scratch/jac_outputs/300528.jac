"""creates a list of integers from a string (counterpart to list_as_string(l))."""
def int_list_from_string(s: str) -> list[int] | None {
    if s == "None" {
        return None;
    }
    return [int(element) for element in s.split(":")];
}