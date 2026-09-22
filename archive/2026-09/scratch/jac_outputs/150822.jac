"""check if a string is numeric"""
def is_num(val: str) -> bool {
    try {
        float(val);
    } except ValueError {
        return False;
    }
    return True;
}