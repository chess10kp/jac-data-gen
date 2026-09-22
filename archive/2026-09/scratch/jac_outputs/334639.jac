"""To check if the string can be converted to int type."""
def checkInt(n: str) -> bool {
    try {
        int(n);
        return True;
    } except ValueError {
        return False;
    }
}