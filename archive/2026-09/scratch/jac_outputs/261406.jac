"""Convert a code point (int) to a string."""
def cp_to_str(cp: int) -> str {
    "%04X" % cp
}