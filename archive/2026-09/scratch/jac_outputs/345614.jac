"""Set text to foregound color."""
def fg(text: str, color: int | str) -> str {
    "\33[38;5;" + str(color) + "m" + text + "\33[0m"
}