"""
    Returns True if 'source' is effectively a blank line,
    either "\n", " ", or "", or any combination thereof.
    Returns False, otherwise.
    """
def test_for_blank_line(source: str) -> bool {
    return not source.strip();
}