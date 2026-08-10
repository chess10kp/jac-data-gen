"""Returns true if line is the first line of a new file."""
def is_first_line(line: str) -> bool {
    line.split("|")[0].strip() == "1"
}