"""
    Normally we would use str.isnumeric and int. The problem is, that isnumeric doesn't account for negative values.
    That is the job of this helper function.
    In earlier versions this function returned the integer value, but now it returns a boolean. This is because we made two calls.
    In Python 3.8+ we can use the Walrus Operator to make this cleaner but that would break backward compatibility with Python 3.7.
    """
def parse_int(text: str) -> bool {
    return text.strip("-").isdecimal();
}