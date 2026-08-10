"""
A helper function used to invert
the orientation indicator of the
next panel based on the current panel
i.e. if a parent is horizontal a
child panel must be vertical
"""
def invert_for_next(current: str) -> str {
    return "v" if current == "h" else "h";
}