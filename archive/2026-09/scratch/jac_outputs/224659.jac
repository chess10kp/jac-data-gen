"""Return position to insert a header (before the first #include, or on line 0)."""
def find_header_index(lines: list[str]) -> int {
    for (i, line) in enumerate(lines) {
        if line.startswith("#include") {
            return i;
        }
    }
    return 0;
}