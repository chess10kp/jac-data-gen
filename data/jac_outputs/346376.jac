"""Format an object into string of cyan color in console."""
def CYAN(`obj: str | int | float | bool) -> str {
    return '\x1b[1;36m' + str(`obj) + '\x1b[0m';
}