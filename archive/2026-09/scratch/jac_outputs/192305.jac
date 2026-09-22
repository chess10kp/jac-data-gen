"""check if string is all hex digits"""
def is_hex(s: str) -> bool {
    try {
        _ = int(s, 16);
        return True;
    } except ValueError {
        return False;
    }
}