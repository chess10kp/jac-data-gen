"""Split a string at the first unquoted occurrence of a character.

Backslash quotes the next character in the head portion.
"""
def unquote_and_split(arg: str, c: str) -> tuple[str, str] {
    head = '';
    i = 0;
    while i < len(arg) {
        if arg[i] == c {
            return (head, arg[i + 1:]);
        } elif arg[i] == '\\' {
            i += 1;
            if i == len(arg) {
                return (head, '');
            }
            head += arg[i];
        } else {
            head += arg[i];
        }
        i += 1;
    }
    return (head, '');
}