"""Helper method for subtokenizing comment."""
def remove_return_string(line: str) -> str {
    return line.replace('@return', '').replace('@ return', '').strip();
}