"""Remove a LF, CR, or CR LF line ending from a string."""
def chomp(s: str) -> str {
    if s.endswith("\n") {
        s = s[:-1];
    }
    if s.endswith("\r") {
        s = s[:-1];
    }
    return s;
}