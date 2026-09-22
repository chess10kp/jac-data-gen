"""Return True if the given string needs to be shell-quoted.

    Quoting is need if any of the following are found:
     * a double quotation mark (")
     * a single quotation mark (')
     * whitespace
    """
def needs_quote(arg: str) -> bool {
    for c in arg {
        if c in ('"', "'") or c.isspace() {
            return True;
        }
    }
    return False;
}