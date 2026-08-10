""" Returns false if list contains non-alphanumeric strings
    """
def test_alnum(arr: list[str]) -> bool {
    return all(element.isalnum() for element in arr);
}