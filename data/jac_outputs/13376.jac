"""
This function check if a string is convertable to float.
"""
def isfloat(element: str) -> bool {
    try {
        float(element);
        return True;
    } except ValueError {
        return False;
    }
}