glob ENCRYPTION_MOD = 20201227;

"""
    Starting from the given public_key, this function applies the transformation
    for loops times and returns the value
    """
def find_encryption(public_key: int, loops: int) -> int {
    value = 1;
    for _ in range(loops) {
        value *= public_key;
        value = value % ENCRYPTION_MOD;
    }
    return value;
}