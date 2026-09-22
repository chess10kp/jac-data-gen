"""Simple numerical ceiling function.

    Args:
        num (float): input number

    Returns:
        int: next lowest integer if num is non-integer, else: num
    """
def floor(num: Any) -> object {
    if (int(num) > num) {
        return (int(num) - 1);
    } else {
        return int(num);
    }
}