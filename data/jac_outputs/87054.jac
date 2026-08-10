"""Return whether a RASP file line is a comment (starts with ';')."""
def is_comment(line: str) -> bool {
    line.startswith(';')
}