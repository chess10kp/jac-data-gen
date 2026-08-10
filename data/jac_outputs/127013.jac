"""Finds the first comment character in the line that isn't in quotes."""
def find_comment(s: str) -> int {
    (quote_single, quote_double, was_backslash) = (False, False, False);
    for (i, ch) in enumerate(s) {
        if was_backslash {
            was_backslash = False;
        } elif ch == '\\' {
            was_backslash = True;
        } elif quote_single {
            if ch == '\'' {
                quote_single = False;
            }
        } elif quote_double {
            if ch == '"' {
                quote_double = False;
            }
        } elif ch == '\'' {
            quote_single = True;
        } elif ch == '"' {
            quote_double = True;
        } elif ch == '#' {
            return i;
        }
    }
    return -1;
}