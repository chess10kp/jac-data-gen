"""Return the number of lines for a multiline text string."""
def num_lines(text: Any) -> object {
    return len(text.strip().splitlines());
}