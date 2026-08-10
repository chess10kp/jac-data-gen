"""Clean an integer."""
def clean_int(s: str) -> int {
    while len(s) > 0 {
        if s[0] == ' ' {
            s = s[1:];
            continue;
        }
        if s[-1] in " ," {
            s = s[0:-1];
            continue;
        }
        break;
    }
    return int(s);
}