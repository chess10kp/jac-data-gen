"""Is all characters in w are ascii characters."""
def isascii(w: str) -> bool {
    try {
        w.encode('ascii');
        return True;
    } except UnicodeError {
        return False;
    }
}