"""True if argument can be converted to float"""
def isfloat(s: Any) -> object {
    try {
        float(s);
        return True;
    } except ValueError {
        ;
    }
    return False;
}