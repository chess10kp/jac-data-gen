"""
Helper method to determine if this string can be cast to a float
:return: True or False
"""
def is_number(s: str) -> bool {
    try {
        float(s);
        return True;
    } except ValueError {
        return False;
    }
}