"""checks if a string is a number"""
def isint(s: str) -> int | bool {
    try {
        return int(s);
    } except ValueError {
        return False;
    }
}