"""Processor for individual line from DeReWo textfile."""
def get_word_from_derewo_line(line: str) -> str | None {
    parts = line.split();
    if len(parts) > 2 {
        return None;
    }
    return parts[0].lower();
}