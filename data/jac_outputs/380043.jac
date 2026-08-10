"""Checks for no, false, f and 0"""
def isFalse(str: str) -> bool {
    return str in ("no", "false", "f", "0");
}