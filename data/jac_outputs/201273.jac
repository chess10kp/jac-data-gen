"""Joins a sequence of objects as strings, with select statements that return
       strings handled correctly. This has O(N^2) performance, so don't use it for
       building up large results.

       This is mostly equivalent to " ".join(strings), except for handling select
       statements correctly."""
def join_cmd(strings: Sequence[str]) -> str {
    result = '';
    for string in strings {
        if type(string) == 'select' {
            result += string;
        } else {
            result += str(string);
        }
    }
    return result;
}